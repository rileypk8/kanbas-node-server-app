import db from "../Database/index.js";
export default function assignmentRoutes(app) {

    app.delete("/api/assignments/:aid", (req, res) => {
        const { aid } = req.params;
        db.assignments = db.assignments.filter((a) => a._id !== aid);
        res.sendStatus(200);
    });

    app.post("/api/courses/:cid/assignments", (req, res) => {
        const { cid } = req.params;
        const newassignment = {
            ...req.body,
            course: cid,
            // _id: new Date().getTime().toString(),
        };
        db.assignments.push(newassignment);
        // console.log("saving new assignment");
        // console.log(newassignment);
        res.send(newassignment);
    });

    app.get("/api/courses/:cid/assignments", (req, res) => {
        const { cid } = req.params;
        // console.log(`getting ${cid}`);
        const assignments = db.assignments.filter((a) => a.course === cid);
        // console.log(assignments);
        res.json(assignments);
    });
    
    app.put("/api/assignments/:aid", (req, res) => {
        const { aid } = req.params;
        const assignmentIndex = db.assignments.findIndex(
            (a) => a._id === aid);
        db.assignments[assignmentIndex] = {
            ...db.assignments[assignmentIndex],
            ...req.body
        };
        res.sendStatus(204);
    });


}
