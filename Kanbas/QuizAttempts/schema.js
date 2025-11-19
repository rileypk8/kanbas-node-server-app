import mongoose from "mongoose";

const answerSchema = new mongoose.Schema({
  question: { type: mongoose.Schema.Types.ObjectId, ref: "QuestionModel" },
  answer: mongoose.Schema.Types.Mixed, // Can be string, boolean, or array
});

const quizAttemptSchema = new mongoose.Schema(
  {
    user: { type: mongoose.Schema.Types.ObjectId, ref: "UserModel", required: true },
    quiz: { type: mongoose.Schema.Types.ObjectId, ref: "QuizModel", required: true },
    attemptNumber: { type: Number, required: true },
    score: { type: Number, default: 0 },
    answers: [answerSchema],
    submittedAt: Date,
    isComplete: { type: Boolean, default: false },
  },
  { collection: "quiz_attempts" }
);

export default quizAttemptSchema;
