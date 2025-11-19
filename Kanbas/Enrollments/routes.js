import * as dao from "./dao.js";

export default function EnrollmentRoutes(app) {
  const enrollUserInCourse = async (req, res) => {
    const { userId, courseId } = req.params;
    try {
      const enrollment = await dao.enrollUserInCourse(userId, courseId);
      res.json(enrollment);
    } catch (err) {
      res.status(400).json({ message: "Already enrolled" });
    }
  };

  const unenrollUserFromCourse = async (req, res) => {
    const { userId, courseId } = req.params;
    const status = await dao.unenrollUserFromCourse(userId, courseId);
    res.json(status);
  };

  const findEnrollmentsByUser = async (req, res) => {
    const { userId } = req.params;
    const enrollments = await dao.findEnrollmentsByUser(userId);
    res.json(enrollments);
  };

  const findCoursesForUser = async (req, res) => {
    const { userId } = req.params;
    const courses = await dao.findCoursesForUser(userId);
    res.json(courses);
  };

  const findEnrollmentsByCourse = async (req, res) => {
    const { courseId } = req.params;
    const enrollments = await dao.findEnrollmentsByCourse(courseId);
    res.json(enrollments);
  };

  app.post("/api/enrollments/:userId/:courseId", enrollUserInCourse);
  app.delete("/api/enrollments/:userId/:courseId", unenrollUserFromCourse);
  app.get("/api/enrollments/user/:userId", findEnrollmentsByUser);
  app.get("/api/enrollments/user/:userId/courses", findCoursesForUser);
  app.get("/api/enrollments/course/:courseId", findEnrollmentsByCourse);
}
