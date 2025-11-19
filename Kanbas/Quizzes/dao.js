import model from "./model.js";

export const createQuiz = (quiz) => {
  delete quiz._id;
  return model.create(quiz);
};

export const findQuizzesByCourse = (courseId) =>
  model.find({ course: courseId });

export const findQuizById = (quizId) => model.findById(quizId);

export const updateQuiz = (quizId, quiz) =>
  model.updateOne({ _id: quizId }, { $set: quiz });

export const deleteQuiz = (quizId) => model.deleteOne({ _id: quizId });

export const publishQuiz = (quizId, published) =>
  model.updateOne({ _id: quizId }, { $set: { published } });
