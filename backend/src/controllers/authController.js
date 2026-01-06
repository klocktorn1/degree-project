const db = require('../db/connection');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const sendEmail = require('../utils/mailer');
const crypto = require('crypto');





const createAccessToken = (user) => {
    return jwt.sign({ id: user.id }, process.env.JWT_SECRET, {
        expiresIn: "15m"
    })
}
const createRefreshToken = (user) => {
    return jwt.sign({ id: user.id }, process.env.JWT_REFRESH_SECRET, {
        expiresIn: "7d"
    })
}


const loginUser = async (req, res) => {
    const { username, password } = req.body;

    if (!username || !password) {
        return res.json({
            ok: false,
            message: "Email and password required"
        });

    }
    try {
        const [row] = await db.query('SELECT * FROM users WHERE username = ?', [username]);
        const user = row[0]
        if (!user) {
            return res.json({
                ok: false,
                message: "Invalid username or password"
            });

        } else {
            if (!row[0].password_hash) {
                return res.json({
                    ok: false,
                    message: "Invalid username or password"
                });
            }
            const match = await bcrypt.compare(password, row[0].password_hash)
            if (!match) {
                return res.json({
                    ok: false,
                    message: "Invalid username or password"
                });
            } else {
                const accessToken = createAccessToken(user);
                const refreshToken = createRefreshToken(user);

                console.log(accessToken);


                res.cookie('accessToken', accessToken, {
                    httpOnly: true,
                    secure: true,
                    sameSite: 'Strict',
                    maxAge: 15 * 60 * 1000 // 15 minutes
                });
                res.cookie("refreshToken", refreshToken, {
                    httpOnly: true,
                    secure: true,
                    sameSite: "Strict",
                    maxAge: 7 * 24 * 60 * 60 * 1000 // 7 d
                })
                await db.query('UPDATE users SET refresh_token = ? WHERE id = ?', [refreshToken, user.id]);

                return res.json({
                    ok: true,
                    message: `Successful login`
                });
            }

        }

    } catch (err) {
        console.log(err);

        return res.status(500).json({ error: `loginUser in authController: ${err.message}` });
    }
};


const logoutUser = async (req, res) => {

    res.clearCookie('accessToken', {
        httpOnly: true,
        secure: true,
        sameSite: 'Strict'
    });
    res.clearCookie('refreshToken', {
        httpOnly: true,
        secure: false,
        sameSite: 'Strict'
    });


    res.json({ ok: true, message: 'Logged out successfully' });
};




// if jwt.verify throws error TokenExpiredError i get 	"message": "Access token expired"
// from server. frontend needs a way to handle this, if TokenExpiredError then point to
// this endpoint here (refreshToken). The refresh token is saved in db so
// frontend needs to access this and send it as payload to this endpoint
const refreshToken = async (req, res) => {
    const token = req.cookies.refreshToken;
    if (!token) return res.status(401).json({ message: "Logged out" })

    try {
        const decoded = jwt.verify(token, process.env.JWT_REFRESH_SECRET);
        const [rows] = await db.query('SELECT * FROM users WHERE id = ? AND refresh_token = ?', [decoded.id, token])
        const user = rows[0]

        if (!user) return res.status(403).json({ message: "Invalid refresh token" })

        const newAccessToken = createAccessToken(user);

        res.cookie('accessToken', newAccessToken, {
            httpOnly: true,
            secure: true,
            sameSite: 'Strict'
        });
        res.json({
            ok: true,
            message: `Successful refresh`,
        })
    } catch (err) {
        res.status(403).json({ message: "Invalid or expired refresh token" });
    }
}

const registerUser = async (req, res) => {
    const { username, email, firstname, lastname, password } = req.body;

    if (!username || !email || !firstname || !lastname || !password) {
        return res.json({
            ok: false,
            message: "Please fill out all the fields"
        });
    }

    const password_hash = await bcrypt.hash(password, 12);
    try {
        await db.query(
            'INSERT INTO users ( username, email, firstname, lastname, password_hash) VALUES (?, ?, ?, ?, ?)',
            [username, email, firstname, lastname, password_hash]
        );
        return res.json({ ok: true, message: `User created successfully` });
    } catch (err) {
        if (err.code === 'ER_DUP_ENTRY' && err.sqlMessage.includes('email')) {
            return res.json({ ok: false, message: 'Email already in use' });
        }
        if (err.code === 'ER_DUP_ENTRY' && err.sqlMessage.includes('username')) {
            return res.json({ ok: false, message: 'Username already in use' });
        }
        return res.json({ ok: false, message: 'Something went wrong during registration', err });
    }
};


const forgotPassword = async (req, res) => {
    const { email } = req.body;


    if (!email) {
        return res.status(400).json({ error: "Email is required" });
    } else {

        try {
            const [row] = await db.query('SELECT * FROM users WHERE email = ?', [email])
            const user = row[0];


            if (!user) {
                return res.json({ message: "Please check your email" })
            } else {
                const token = crypto.randomBytes(32).toString('hex');
                const expires = new Date(Date.now() + 60 * 60 * 1000);

                const token_hash = await bcrypt.hash(token, 12);


                await db.query(
                    'UPDATE users SET reset_token_hash = ?, reset_token_expires_at = ? WHERE email = ?',
                    [token_hash, expires, email]
                );

                const resetLink = `http://localhost:3000/auth/forgot-password/${user.id}/${token}`;

                await sendEmail({
                    to: email,
                    subject: "reset your password",
                    html: `<p>Click <a href="${resetLink}">here</a> to reset your password</p>`
                })

                return res.json({ message: "Please check your email" })

            }

        } catch (err) {
            res.status(500).json({ error: `forgotPassword inside authController ${err.message}` })

        }

    }



}



const resetPassword = async (req, res) => {
    const { id, token } = req.params;
    const { newPassword } = req.body;

    try {

        const [rows] = await db.query('SELECT * FROM users WHERE id = ?', [id])
        const user = rows[0]
        const resetTokenMatch = await bcrypt.compare(token, user.reset_token_hash)
        const passwordMatch = await bcrypt.compare(newPassword, user.password_hash)

        if (!resetTokenMatch) {
            return res.status(400).json({ message: "Invalid or expired reset token" })
        } else if (passwordMatch) {
            return res.status(400).json({ message: "Please do not reuse old password!" })
        } else {
            const password_hash = await bcrypt.hash(newPassword, 12);

            await db.query('UPDATE users SET password_hash = ? WHERE id = ?;', [password_hash, user.id])
            await db.query('UPDATE users SET reset_token_hash = NULL, reset_token_expires_at = NULL WHERE id = ?;', [user.id])

            return res.json({ message: "Password has been reset successfully" })

        }

    } catch (err) {
        return res.status(500).json({ error: `resetPassword inside authController: ${err.message}` })
    }

}


const googleCallback = async (req, res) => {
    const { code } = req.query;

    if (!code) return res.status(400).send('No code provided');


    try {
        const params = new URLSearchParams();
        params.append('code', code);
        params.append('client_id', process.env.GOOGLE_CLIENT_ID);
        params.append('client_secret', process.env.GOOGLE_CLIENT_SECRET);
        params.append('redirect_uri', 'http://localhost:3000/auth/google/callback');
        params.append('grant_type', 'authorization_code');

        const tokenRes = await fetch('https://oauth2.googleapis.com/token', {
            method: 'POST',
            headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
            body: params.toString(),
        });
        const tokenData = await tokenRes.json();

        // 2️⃣ Decode Google ID token
        const googleUser = jwt.decode(tokenData.id_token);
        const providerUserId = googleUser.sub;
        const email = googleUser.email;
        const firstName = googleUser.given_name || '';
        const lastName = googleUser.family_name || '';


        const [authRow] = await db.query(
            'SELECT * FROM auth_providers WHERE provider_user_id = ? AND provider = ?',
            [providerUserId, 'google']
        );

        if (authRow[0]) {
            console.log(authRow[0]);

            const [userRow] = await db.query('SELECT * FROM users WHERE id = ?', [authRow[0].user_id])
            const user = userRow[0]

            const accessToken = createAccessToken(user);
            const refreshToken = createRefreshToken(user);

            res.cookie('accessToken', accessToken, {
                httpOnly: true,
                secure: true,
                sameSite: 'Strict',
                maxAge: 15 * 60 * 1000
            });
            res.cookie('refreshToken', refreshToken, {
                httpOnly: true,
                secure: true,
                sameSite: 'Strict',
                maxAge: 7 * 24 * 60 * 60 * 1000
            });

            await db.query('UPDATE users SET refresh_token = ? WHERE id = ?', [refreshToken, user.id]);

        } else {
            const [result] = await db.query(
                'INSERT INTO users (email, firstname, lastname) VALUES (?, ?, ?)',
                [email, firstName, lastName]
            );

            const userId = result.insertId

            await db.query(
                'INSERT INTO auth_providers (user_id, provider, provider_user_id) VALUES (?, ?, ?)',
                [userId, "google", providerUserId]
            );



            const user = { id: userId, email, firstname: firstName, lastname: lastName };

            const accessToken = createAccessToken(user);
            const refreshToken = createRefreshToken(user);

            res.cookie('accessToken', accessToken, {
                httpOnly: true,
                secure: true,
                sameSite: 'Strict',
                maxAge: 15 * 60 * 1000
            });
            res.cookie('refreshToken', refreshToken, {
                httpOnly: true,
                secure: true,
                sameSite: 'Strict',
                maxAge: 7 * 24 * 60 * 60 * 1000
            });
            await db.query('UPDATE users SET refresh_token = ? WHERE id = ?', [refreshToken, user.id]);

        }



        return res.redirect('https://degree-project-production-6775.up.railway.app/dashboard');

    } catch (err) {
        console.log(err);

        return res.status(500).send({message: 'Google login failed ', error: err.message});

    }

}

const githubCallback = async (req, res) => {


    const { code } = req.query;


    if (!code) return res.status(400).send('No code provided');


    try {
        const params = new URLSearchParams({
            client_id: process.env.GITHUB_CLIENT_ID,
            client_secret: process.env.GITHUB_CLIENT_SECRET,
            code: code,
            redirect_uri: "http://localhost:3000/auth/github/callback"
        });

        const tokenRes = await fetch('https://github.com/login/oauth/access_token', {
            method: 'POST',
            headers: {
                Accept: 'application/json',
                'Content-Type': 'application/x-www-form-urlencoded'

            },
            body: params.toString()
        });
        const tokenData = await tokenRes.json();

        const accessToken = tokenData.access_token;


        const userRes = await fetch('https://api.github.com/user', {
            headers: { Authorization: `token ${accessToken}` }
        });

        const githubUser = await userRes.json();



        const providerUserId = githubUser.id

        const [authRow] = await db.query(
            'SELECT * FROM auth_providers WHERE provider_user_id = ? AND provider = ?',
            [providerUserId, 'github']
        );

        if (authRow[0]) {

            const [userRow] = await db.query('SELECT * FROM users WHERE id = ?', [authRow[0].user_id])
            const user = userRow[0]

            const accessToken = createAccessToken(user);
            const refreshToken = createRefreshToken(user);

            res.cookie('accessToken', accessToken, {
                httpOnly: true,
                secure: true,
                sameSite: 'Strict',
                maxAge: 15 * 60 * 1000
            });
            res.cookie('refreshToken', refreshToken, {
                httpOnly: true,
                secure: true,
                sameSite: 'Strict',
                maxAge: 7 * 24 * 60 * 60 * 1000
            });

            await db.query('UPDATE users SET refresh_token = ? WHERE id = ?', [refreshToken, user.id]);

        } else {
            const [result] = await db.query(
                'INSERT INTO users (firstname, lastname) VALUES (?, ?)',
                [null, null]
            );

            const userId = result.insertId

            await db.query(
                'INSERT INTO auth_providers (user_id, provider, provider_user_id) VALUES (?, ?, ?)',
                [userId, "github", providerUserId]
            );



            const user = { id: userId };

            const accessToken = createAccessToken(user);
            const refreshToken = createRefreshToken(user);

            res.cookie('accessToken', accessToken, {
                httpOnly: true,
                secure: true,
                sameSite: 'Strict',
                maxAge: 15 * 60 * 1000
            });
            res.cookie('refreshToken', refreshToken, {
                httpOnly: true,
                secure: true,
                sameSite: 'Strict',
                maxAge: 7 * 24 * 60 * 60 * 1000
            });
            await db.query('UPDATE users SET refresh_token = ? WHERE id = ?', [refreshToken, user.id]);

        }


        return res.redirect('https://degree-project-production-6775.up.railway.app/dashboard');

    } catch (err) {
        console.log(err);

        return res.status(500).send({message: 'Github login failed ', error: err.message});

    }

}

module.exports = {
    loginUser,
    registerUser,
    refreshToken,
    forgotPassword,
    resetPassword,
    logoutUser,
    githubCallback,
    googleCallback
}