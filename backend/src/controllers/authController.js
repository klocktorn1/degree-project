const db = require('../db/connection');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const sendEmail = require('../utils/mailer');
const crypto = require('crypto');





const createAccessToken = (user) => {
    return jwt.sign({ user: user.id, email: user.email }, process.env.JWT_SECRET, {
        expiresIn: "15m"
    })
}
const createRefreshToken = (user) => {
    return jwt.sign({ user: user.id, email: user.email }, process.env.JWT_REFRESH_SECRET, {
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

    const saltRounds = 12;
    const password_hash = await bcrypt.hash(password, saltRounds);
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

                await db.query(
                    'INSERT INTO password_resets (user_id, token, expires_at) VALUES (?, ?, ?)',
                    [user.id, token, expires]
                );
                console.log("asdasasdassadassassasadsadsda");
                
                const resetLink = `http://localhost:3000/auth/reset-password/${token}`;

                await sendEmail({
                    to: email,
                    subject: "reset your password",
                    html: `<p>Click <a href="${resetLink}">here</a> to reset your password</p>`
                })

            }

        } catch (err) {
            res.status(500).json({ error: `forgotPassword inside authController ${err.message}` })

        }

    }



}



const resetPassword = async (req, res) => {
    const { token } = req.params;
    const { newPassword } = req.body;

    try {

        const [rows] = await db.query('SELECT * FROM password_resets WHERE token = ? AND expires_at > NOW()', [token])

        if (rows.length === 0) {
            return res.status(400).json({ message: "Invalid or expired reset token" })
        } else {
            const resetRecord = rows[0]
            const password_hash = await bcrypt.hash(newPassword, 12);

            await db.query('UPDATE users SET password_hash = ? WHERE id = ?', [password_hash, resetRecord.user_id])
            await db.query('DELETE from password_resets WHERE token = ?', [token])

            res.json({ message: "Password has been reset successfully" })

        }

    } catch (err) {
        res.status(500).json({ error: `resetPassword inside authController ${err.message}` })
    }

}

module.exports = {
    loginUser,
    registerUser,
    refreshToken,
    forgotPassword,
    resetPassword
}