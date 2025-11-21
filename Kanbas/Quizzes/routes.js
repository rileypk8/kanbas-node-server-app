import * as quizDao from "./dao.js";
import * as questionDao from "../Questions/dao.js";
import * as attemptDao from "../QuizAttempts/dao.js";

export default function QuizRoutes(app) {
  // Quiz CRUD operations
  const createQuiz = async (req, res) => {
    const currentUser = req.session["currentUser"];
    if (!currentUser || currentUser.role !== "FACULTY") {
      res.sendStatus(403);
      return;
    }
    const { cid } = req.params;
    const quiz = { ...req.body, course: cid };
    const newQuiz = await quizDao.createQuiz(quiz);
    res.json(newQuiz);
  };

  const findQuizzesByCourse = async (req, res) => {
    const { cid } = req.params;
    const currentUser = req.session["currentUser"];
    let quizzes = await quizDao.findQuizzesByCourse(cid);
    // Filter unpublished quizzes for non-faculty
    if (!currentUser || currentUser.role !== "FACULTY") {
      quizzes = quizzes.filter((q) => q.published);
    }
    res.json(quizzes);
  };

  const findQuizById = async (req, res) => {
    const { qid } = req.params;
    const quiz = await quizDao.findQuizById(qid);
    res.json(quiz);
  };

  const updateQuiz = async (req, res) => {
    const currentUser = req.session["currentUser"];
    if (!currentUser || currentUser.role !== "FACULTY") {
      res.sendStatus(403);
      return;
    }
    const { qid } = req.params;
    const status = await quizDao.updateQuiz(qid, req.body);
    res.json(status);
  };

  const deleteQuiz = async (req, res) => {
    const currentUser = req.session["currentUser"];
    if (!currentUser || currentUser.role !== "FACULTY") {
      res.sendStatus(403);
      return;
    }
    const { qid } = req.params;
    await questionDao.deleteQuestionsByQuiz(qid);
    const status = await quizDao.deleteQuiz(qid);
    res.json(status);
  };

  const publishQuiz = async (req, res) => {
    const currentUser = req.session["currentUser"];
    if (!currentUser || currentUser.role !== "FACULTY") {
      res.sendStatus(403);
      return;
    }
    const { qid } = req.params;
    const { published } = req.body;
    const status = await quizDao.publishQuiz(qid, published);
    res.json(status);
  };

  // Question CRUD operations
  const createQuestion = async (req, res) => {
    const currentUser = req.session["currentUser"];
    if (!currentUser || currentUser.role !== "FACULTY") {
      res.sendStatus(403);
      return;
    }
    const { qid } = req.params;
    const question = { ...req.body, quiz: qid };
    const newQuestion = await questionDao.createQuestion(question);
    res.json(newQuestion);
  };

  const findQuestionsByQuiz = async (req, res) => {
    const { qid } = req.params;
    const questions = await questionDao.findQuestionsByQuiz(qid);
    res.json(questions);
  };

  const updateQuestion = async (req, res) => {
    const currentUser = req.session["currentUser"];
    if (!currentUser || currentUser.role !== "FACULTY") {
      res.sendStatus(403);
      return;
    }
    const { questionId } = req.params;
    const status = await questionDao.updateQuestion(questionId, req.body);
    res.json(status);
  };

  const deleteQuestion = async (req, res) => {
    const currentUser = req.session["currentUser"];
    if (!currentUser || currentUser.role !== "FACULTY") {
      res.sendStatus(403);
      return;
    }
    const { questionId } = req.params;
    const status = await questionDao.deleteQuestion(questionId);
    res.json(status);
  };

  // Quiz attempt operations
  const startAttempt = async (req, res) => {
    const { qid } = req.params;
    const userId = req.session["currentUser"]?._id;

    if (!userId) {
      res.sendStatus(401);
      return;
    }

    const quiz = await quizDao.findQuizById(qid);
    const attemptCount = await attemptDao.countUserAttempts(userId, qid);

    // Check attempt limits (only if limit is set and > 0)
    if (quiz.howManyAttempts > 0 && attemptCount >= quiz.howManyAttempts) {
      res.status(403).json({ message: "Maximum attempts reached" });
      return;
    }

    const attempt = {
      user: userId,
      quiz: qid,
      attemptNumber: attemptCount + 1,
      answers: [],
      isComplete: false,
    };

    const newAttempt = await attemptDao.createAttempt(attempt);
    res.json(newAttempt);
  };

  const saveAttemptProgress = async (req, res) => {
    const { attemptId } = req.params;
    const status = await attemptDao.updateAttempt(attemptId, req.body);
    res.json(status);
  };

  const submitAttempt = async (req, res) => {
    const { attemptId } = req.params;
    const attempt = await attemptDao.findAttemptById(attemptId);
    const questions = await questionDao.findQuestionsByQuiz(attempt.quiz);

    // Calculate score from submitted answers
    let score = 0;
    const submittedAnswers = req.body.answers || [];
    submittedAnswers.forEach((answer) => {
      const question = questions.find((q) => q._id.toString() === answer.question.toString());
      if (!question) return;

      let isCorrect = false;
      if (question.type === "MULTIPLE_CHOICE") {
        const correctChoice = question.choices.find((c) => c.isCorrect);
        isCorrect = answer.answer === correctChoice?.text;
      } else if (question.type === "TRUE_FALSE") {
        isCorrect = answer.answer === question.correctAnswer;
      } else if (question.type === "FILL_BLANK") {
        const answerLower = answer.answer?.toLowerCase().trim();
        isCorrect = question.possibleAnswers.some(
          (possible) => possible.toLowerCase().trim() === answerLower
        );
      }

      if (isCorrect) {
        score += question.points;
      }
    });

    const status = await attemptDao.updateAttempt(attemptId, {
      score,
      submittedAt: new Date(),
      isComplete: true,
      answers: submittedAnswers,
    });

    res.json({ score, status });
  };

  const getUserAttempts = async (req, res) => {
    const { qid } = req.params;
    const userId = req.session["currentUser"]?._id;

    if (!userId) {
      res.sendStatus(401);
      return;
    }

    const attempts = await attemptDao.findAttemptsByUserAndQuiz(userId, qid);
    res.json(attempts);
  };

  // Quiz routes
  app.post("/api/courses/:cid/quizzes", createQuiz);
  app.get("/api/courses/:cid/quizzes", findQuizzesByCourse);
  app.get("/api/quizzes/:qid", findQuizById);
  app.put("/api/quizzes/:qid", updateQuiz);
  app.delete("/api/quizzes/:qid", deleteQuiz);
  app.put("/api/quizzes/:qid/publish", publishQuiz);

  // Question routes
  app.post("/api/quizzes/:qid/questions", createQuestion);
  app.get("/api/quizzes/:qid/questions", findQuestionsByQuiz);
  app.put("/api/questions/:questionId", updateQuestion);
  app.delete("/api/questions/:questionId", deleteQuestion);

  // Attempt routes
  app.post("/api/quizzes/:qid/attempts", startAttempt);
  app.put("/api/attempts/:attemptId", saveAttemptProgress);
  app.post("/api/attempts/:attemptId/submit", submitAttempt);
  app.get("/api/quizzes/:qid/attempts", getUserAttempts);
}
