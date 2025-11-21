import * as dao from "./dao.js";

export default function UserRoutes(app) {
    const createUser = async (req, res) => {
        const user = await dao.createUser(req.body);
        res.json(user);
    };
    const deleteUser = async (req, res) => {
        const status = await dao.deleteUser(req.params.userId);
        res.json(status);
    };
    const findAllUsers = async (req, res) => {
        const { role, name } = req.query;
        if (role) {
            const users = await dao.findUsersByRole(role);
            res.json(users);
            return;
        }
        if (name) {
            const users = await dao.findUsersByPartialName(name);
            res.json(users);
            return;
        }
        const users = await dao.findAllUsers();
        res.json(users);
    };
    const findUserById = async (req, res) => {
        const user = await dao.findUserById(req.params.userId);
        res.json(user);
    };
    const updateUser = async (req, res) => {
        const { userId } = req.params;
        const status = await dao.updateUser(userId, req.body);
        res.json(status);
    };
    const signup = async (req, res) => {
        console.log('[SIGNUP] Request body:', req.body);
        const user = await dao.findUserByUsername(req.body.username);
        if (user) {
            console.log('[SIGNUP] Username already exists:', req.body.username);
            res.status(400).json(
                                 { message: "Username already taken" });
            return;
        }
        const currentUser = await dao.createUser(req.body);
        console.log('[SIGNUP] Created user:', currentUser._id, currentUser.username);
        req.session["currentUser"] = currentUser;
        console.log('[SIGNUP] Session set. Session ID:', req.sessionID);
        console.log('[SIGNUP] Session data:', req.session);
        res.json(currentUser);
    };
    const signin = async (req, res) => {
        const { username, password } = req.body;
        console.log('[SIGNIN] Attempting login for:', username);
        const currentUser = await dao.findUserByCredentials(username, password);
        if (currentUser) {
            console.log('[SIGNIN] User found:', currentUser._id, currentUser.username);
            req.session["currentUser"] = currentUser;
            console.log('[SIGNIN] Session set. Session ID:', req.sessionID);
            res.json(currentUser);
        } else {
            console.log('[SIGNIN] User NOT found or password mismatch');
            res.status(401).json({ message: "Unable to login. Try again later." });
        }
    };
    const signout = (req, res) => {
        req.session.destroy();
        res.sendStatus(200);
    };
    const profile = (req, res) => {
        console.log('[PROFILE] Session ID:', req.sessionID);
        console.log('[PROFILE] Session data:', req.session);
        const currentUser = req.session["currentUser"];
        console.log('[PROFILE] Current user:', currentUser ? currentUser.username : 'NONE');
        if (!currentUser) {
            console.log('[PROFILE] No user in session - returning 401');
            res.sendStatus(401);
            return;
        }
        res.json(currentUser);
    };
    app.post("/api/users", createUser);
    app.get("/api/users", findAllUsers);
    app.get("/api/users/:userId", findUserById);
    app.put("/api/users/:userId", updateUser);
    app.delete("/api/users/:userId", deleteUser);
    app.post("/api/users/signup", signup);
    app.post("/api/users/signin", signin);
    app.post("/api/users/signout", signout);
    app.post("/api/users/profile", profile);
}
