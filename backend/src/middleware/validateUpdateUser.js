module.exports = function validateUpdateUser(req, res, next) {


    const {id} = req.params;
    const { email, firstname, lastname, password } = req.body;
    console.log(req.body)

    if (!id) {
        res.status(400).json({ error: "Missing id" })
    }

    const updatableFields = { email, firstname, lastname, password };
    const fieldsToUpdate = Object.keys(updatableFields).filter(key => updatableFields[key] !== undefined);

    console.log(fieldsToUpdate);

    if (fieldsToUpdate.length === 0) {
        res.status(400).json({error: "Please enter at least one field to update"})
    }

    next();
};
