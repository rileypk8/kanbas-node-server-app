import mongoose from "mongoose";

const choiceSchema = new mongoose.Schema({
  text: String,
  isCorrect: Boolean,
});

const questionSchema = new mongoose.Schema(
  {
    title: String,
    quiz: { type: mongoose.Schema.Types.ObjectId, ref: "QuizModel", required: true },
    type: {
      type: String,
      enum: ["MULTIPLE_CHOICE", "TRUE_FALSE", "FILL_BLANK"],
      required: true,
    },
    points: { type: Number, default: 0 },
    questionText: String,
    // For multiple choice questions
    choices: [choiceSchema],
    // For true/false questions
    correctAnswer: Boolean,
    // For fill in the blank questions
    possibleAnswers: [String],
  },
  { collection: "questions" }
);

export default questionSchema;
