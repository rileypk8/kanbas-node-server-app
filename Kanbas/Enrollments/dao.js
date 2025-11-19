import model from "./model.js";

export const enrollUserInCourse = (userId, courseId) => {
  return model.create({ user: userId, course: courseId });
};

export const unenrollUserFromCourse = (userId, courseId) => {
  return model.deleteOne({ user: userId, course: courseId });
};

export const findEnrollmentsByUser = (userId) => model.find({ user: userId });

export const findEnrollmentsByCourse = (courseId) =>
  model.find({ course: courseId });

export const isUserEnrolledInCourse = async (userId, courseId) => {
  const enrollment = await model.findOne({ user: userId, course: courseId });
  return !!enrollment;
};

export const findCoursesForUser = async (userId) => {
  const enrollments = await model.find({ user: userId });
  return enrollments.map((e) => e.course);
};
