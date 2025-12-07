const db = require('../db/connection');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const sendEmail = require('../utils/mailer');
const crypto = require('crypto');





const createAccessToken = (user) => {
    return jwt.sign({ id: user.id, email: user.email }, process.env.JWT_SECRET, {
        expiresIn: "15m"
    })
}
const createRefreshToken = (user) => {
    return jwt.sign({ id: user.id, email: user.email }, process.env.JWT_REFRESH_SECRET, {
        expiresIn: "7d"
    })
}


const loginUser = async (req, res) => {
    const { email, password } = req.body;
    try {
        const [row] = await db.query('SELECT * FROM users WHERE email = ?', [email]);
        const user = row[0]

        if (!user) {
            return res.status(401).json({ message: "Invalid email or password" })
        } else {            
            const match = await bcrypt.compare(password, row[0].password_hash)
            if (!match) {
                return res.status(401).json({ message: "Invalid email or password" });
            } else {
                const accessToken = createAccessToken(user);
                const refreshToken = createRefreshToken(user);
                res.cookie("refreshToken", refreshToken, {
                    httpOnly: true,
                    secure: false,
                    sameSite: "strict",
                    maxAge: 7 * 24 * 60 * 60 * 1000 // 7 d
                })
                await db.query('UPDATE users SET refresh_token = ? WHERE id = ?', [refreshToken, user.id]);

                return res.json({
                    message: `Successful login`,
                    accessToken,
                    refreshToken
                });
            }

        }

    } catch (err) {
        return res.status(500).json({ error: `loginUser in authController: ${err.message}` });
    }
};

// if jwt.verify throws error TokenExpiredError i get 	"message": "Access token expired"
// from server. frontend needs a way to handle this, if TokenExpiredError then point to
// this endpoint here (refreshToken). The refresh token is saved in db so
// frontend needs to access this and send it as payload to this endpoint
const refreshToken = async (req, res) => {
    const { token } = req.body;
    if (!token) return res.status(401).json({ message: "No token provided" })

    try {
        const decoded = jwt.verify(token, process.env.JWT_REFRESH_SECRET);
        const [rows] = await db.query('SELECT * FROM users WHERE id = ? AND refresh_token = ?', [decoded.id, token])
        const user = rows[0]

        if (!user) return res.status(403).json({ message: "Invalid refresh token" })

        const newAccessToken = createAccessToken(user);
        res.json({ accessToken: newAccessToken })
    } catch (err) {
        res.status(403).json({ message: "Invalid or expired refresh token" });
    }
}

const registerUser = async (req, res) => {
    const { username, email, firstname, lastname, password } = req.body;

    const password_hash = await bcrypt.hash(password, 12);
    try {
        const [result] = await db.query(
            'INSERT INTO users (username, email, firstname, lastname, password_hash) VALUES (?, ?, ?, ?, ?)',
            [username, email, firstname, lastname, password_hash]
        );
        res.json({ message: `User created successfully with id: ${result.insertId}` });
    } catch (err) {
        res.status(500).json({ error: `registerUser in authController: ${err.message}` });
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
        res.status(500).json({ error: `resetPassword inside authController: ${err.message}` })
    }

}

module.exports = {
    loginUser,
    registerUser,
    refreshToken,
    forgotPassword,
    resetPassword
}