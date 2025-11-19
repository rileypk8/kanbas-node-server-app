import model from "./model.js";

export const createAttempt = (attempt) => {
  delete attempt._id;
  return model.create(attempt);
};

export const findAttemptsByUserAndQuiz = (userId, quizId) =>
  model.find({ user: userId, quiz: quizId }).sort({ attemptNumber: -1 });

export const findAttemptById = (attemptId) => model.findById(attemptId);

export const updateAttempt = (attemptId, attempt) =>
  model.updateOne({ _id: attemptId }, { $set: attempt });

export const deleteAttempt = (attemptId) => model.deleteOne({ _id: attemptId });

export const countUserAttempts = (userId, quizId) =>
  model.countDocuments({ user: userId, quiz: quizId, isComplete: true });

export const getLatestAttempt = (userId, quizId) =>
  model.findOne({ user: userId, quiz: quizId, isComplete: true })
    .sort({ submittedAt: -1 })
    .limit(1);
