import model from "./model.js";

export const createQuestion = (question) => {
  delete question._id;
  return model.create(question);
};

export const findQuestionsByQuiz = (quizId) => model.find({ quiz: quizId });

export const findQuestionById = (questionId) => model.findById(questionId);

export const updateQuestion = (questionId, question) =>
  model.updateOne({ _id: questionId }, { $set: question });

export const deleteQuestion = (questionId) =>
  model.deleteOne({ _id: questionId });

export const deleteQuestionsByQuiz = (quizId) =>
  model.deleteMany({ quiz: quizId });
