#!/bin/bash

BASE_URL="http://negroni.local:4000"
COURSE_ID="RS101"
PASS=0
FAIL=0

# Helper to check HTTP status
check_status() {
  local expected=$1
  local actual=$2
  local test_name=$3
  if [ "$actual" == "$expected" ]; then
    echo "    ✓ $test_name"
    ((PASS++))
  else
    echo "    ✗ $test_name (expected $expected, got $actual)"
    ((FAIL++))
  fi
}

# Helper to check value
check_value() {
  local expected=$1
  local actual=$2
  local test_name=$3
  if [ "$actual" == "$expected" ]; then
    echo "    ✓ $test_name"
    ((PASS++))
  else
    echo "    ✗ $test_name (expected $expected, got $actual)"
    ((FAIL++))
  fi
}

echo "=== Quiz System Integration Tests ==="
echo ""

# Cleanup
echo "[SETUP] Cleaning up..."
mongosh --quiet kanbas --eval "db.users.deleteMany({username: /^test_/})" > /dev/null
mongosh --quiet kanbas --eval "db.quizzes.deleteMany({title: /^Test/})" > /dev/null
mongosh --quiet kanbas --eval "db.quizattempts.deleteMany({})" > /dev/null
rm -f faculty_cookies.txt student_cookies.txt student2_cookies.txt anon_cookies.txt

# Create users
echo "[SETUP] Creating test users..."
FACULTY_RESP=$(curl -s -c faculty_cookies.txt -X POST "$BASE_URL/api/users/signup" \
  -H "Content-Type: application/json" \
  -d '{"username":"test_faculty","password":"pass123","role":"FACULTY"}')
FACULTY_ID=$(echo $FACULTY_RESP | python3 -c "import sys, json; print(json.load(sys.stdin)['_id'])")

STUDENT_RESP=$(curl -s -c student_cookies.txt -X POST "$BASE_URL/api/users/signup" \
  -H "Content-Type: application/json" \
  -d '{"username":"test_student","password":"pass123","role":"STUDENT"}')
STUDENT_ID=$(echo $STUDENT_RESP | python3 -c "import sys, json; print(json.load(sys.stdin)['_id'])")

STUDENT2_RESP=$(curl -s -c student2_cookies.txt -X POST "$BASE_URL/api/users/signup" \
  -H "Content-Type: application/json" \
  -d '{"username":"test_student2","password":"pass123","role":"STUDENT"}')
STUDENT2_ID=$(echo $STUDENT2_RESP | python3 -c "import sys, json; print(json.load(sys.stdin)['_id'])")

echo "    Faculty: $FACULTY_ID"
echo "    Student1: $STUDENT_ID"
echo "    Student2: $STUDENT2_ID"
echo ""

#############################################
# SECTION 1: Question Types
#############################################
echo "=== 1. QUESTION TYPES ==="

# Create quiz with all question types
QUIZ_RESP=$(curl -s -b faculty_cookies.txt -X POST "$BASE_URL/api/courses/$COURSE_ID/quizzes" \
  -H "Content-Type: application/json" \
  -d '{"title":"Test Quiz - Question Types","published":true,"howManyAttempts":10}')
QUIZ_ID=$(echo $QUIZ_RESP | python3 -c "import sys, json; print(json.load(sys.stdin)['_id'])")
echo "[1.1] Created quiz: $QUIZ_ID"

# Multiple choice
Q_MC=$(curl -s -b faculty_cookies.txt -X POST "$BASE_URL/api/quizzes/$QUIZ_ID/questions" \
  -H "Content-Type: application/json" \
  -d '{"title":"MC","type":"MULTIPLE_CHOICE","points":10,"questionText":"What is 2+2?","choices":[{"text":"3","isCorrect":false},{"text":"4","isCorrect":true},{"text":"5","isCorrect":false}]}')
Q_MC_ID=$(echo $Q_MC | python3 -c "import sys, json; print(json.load(sys.stdin)['_id'])")

# True/False
Q_TF=$(curl -s -b faculty_cookies.txt -X POST "$BASE_URL/api/quizzes/$QUIZ_ID/questions" \
  -H "Content-Type: application/json" \
  -d '{"title":"TF","type":"TRUE_FALSE","points":10,"questionText":"The sky is blue","correctAnswer":true}')
Q_TF_ID=$(echo $Q_TF | python3 -c "import sys, json; print(json.load(sys.stdin)['_id'])")

# Fill in blank - single answer
Q_FIB=$(curl -s -b faculty_cookies.txt -X POST "$BASE_URL/api/quizzes/$QUIZ_ID/questions" \
  -H "Content-Type: application/json" \
  -d '{"title":"FIB","type":"FILL_BLANK","points":10,"questionText":"The capital of France is ___","possibleAnswers":["Paris"]}')
Q_FIB_ID=$(echo $Q_FIB | python3 -c "import sys, json; print(json.load(sys.stdin)['_id'])")

# Fill in blank - multiple possible answers
Q_FIB2=$(curl -s -b faculty_cookies.txt -X POST "$BASE_URL/api/quizzes/$QUIZ_ID/questions" \
  -H "Content-Type: application/json" \
  -d '{"title":"FIB2","type":"FILL_BLANK","points":10,"questionText":"The color of grass is ___","possibleAnswers":["green","Green","GREEN"]}')
Q_FIB2_ID=$(echo $Q_FIB2 | python3 -c "import sys, json; print(json.load(sys.stdin)['_id'])")

echo "    Questions: MC=$Q_MC_ID, TF=$Q_TF_ID, FIB=$Q_FIB_ID, FIB2=$Q_FIB2_ID"

# Test: All correct answers
ATTEMPT=$(curl -s -b student_cookies.txt -X POST "$BASE_URL/api/quizzes/$QUIZ_ID/attempts")
ATTEMPT_ID=$(echo $ATTEMPT | python3 -c "import sys, json; print(json.load(sys.stdin)['_id'])")
SUBMIT=$(curl -s -b student_cookies.txt -X POST "$BASE_URL/api/attempts/$ATTEMPT_ID/submit" \
  -H "Content-Type: application/json" \
  -d "{\"answers\":[{\"question\":\"$Q_MC_ID\",\"answer\":\"4\"},{\"question\":\"$Q_TF_ID\",\"answer\":true},{\"question\":\"$Q_FIB_ID\",\"answer\":\"Paris\"},{\"question\":\"$Q_FIB2_ID\",\"answer\":\"green\"}]}")
SCORE=$(echo $SUBMIT | python3 -c "import sys, json; print(json.load(sys.stdin)['score'])")
check_value "40" "$SCORE" "All question types correct = 40 pts"

# Test: Fill-in-blank case insensitive
ATTEMPT=$(curl -s -b student2_cookies.txt -X POST "$BASE_URL/api/quizzes/$QUIZ_ID/attempts")
ATTEMPT_ID=$(echo $ATTEMPT | python3 -c "import sys, json; print(json.load(sys.stdin)['_id'])")
SUBMIT=$(curl -s -b student2_cookies.txt -X POST "$BASE_URL/api/attempts/$ATTEMPT_ID/submit" \
  -H "Content-Type: application/json" \
  -d "{\"answers\":[{\"question\":\"$Q_MC_ID\",\"answer\":\"4\"},{\"question\":\"$Q_TF_ID\",\"answer\":true},{\"question\":\"$Q_FIB_ID\",\"answer\":\"paris\"},{\"question\":\"$Q_FIB2_ID\",\"answer\":\"GREEN\"}]}")
SCORE=$(echo $SUBMIT | python3 -c "import sys, json; print(json.load(sys.stdin)['score'])")
check_value "40" "$SCORE" "Fill-in-blank case insensitive = 40 pts"

# Cleanup
curl -s -b faculty_cookies.txt -X DELETE "$BASE_URL/api/quizzes/$QUIZ_ID" > /dev/null
echo ""

#############################################
# SECTION 2: Scoring
#############################################
echo "=== 2. SCORING ==="

QUIZ_RESP=$(curl -s -b faculty_cookies.txt -X POST "$BASE_URL/api/courses/$COURSE_ID/quizzes" \
  -H "Content-Type: application/json" \
  -d '{"title":"Test Quiz - Scoring","published":true,"howManyAttempts":10}')
QUIZ_ID=$(echo $QUIZ_RESP | python3 -c "import sys, json; print(json.load(sys.stdin)['_id'])")
echo "[2.1] Created quiz: $QUIZ_ID"

Q1=$(curl -s -b faculty_cookies.txt -X POST "$BASE_URL/api/quizzes/$QUIZ_ID/questions" \
  -H "Content-Type: application/json" \
  -d '{"title":"Q1","type":"MULTIPLE_CHOICE","points":25,"questionText":"Q1","choices":[{"text":"A","isCorrect":true},{"text":"B","isCorrect":false}]}')
Q1_ID=$(echo $Q1 | python3 -c "import sys, json; print(json.load(sys.stdin)['_id'])")

Q2=$(curl -s -b faculty_cookies.txt -X POST "$BASE_URL/api/quizzes/$QUIZ_ID/questions" \
  -H "Content-Type: application/json" \
  -d '{"title":"Q2","type":"TRUE_FALSE","points":25,"questionText":"Q2","correctAnswer":true}')
Q2_ID=$(echo $Q2 | python3 -c "import sys, json; print(json.load(sys.stdin)['_id'])")

Q3=$(curl -s -b faculty_cookies.txt -X POST "$BASE_URL/api/quizzes/$QUIZ_ID/questions" \
  -H "Content-Type: application/json" \
  -d '{"title":"Q3","type":"FILL_BLANK","points":25,"questionText":"Q3","possibleAnswers":["correct"]}')
Q3_ID=$(echo $Q3 | python3 -c "import sys, json; print(json.load(sys.stdin)['_id'])")

Q4=$(curl -s -b faculty_cookies.txt -X POST "$BASE_URL/api/quizzes/$QUIZ_ID/questions" \
  -H "Content-Type: application/json" \
  -d '{"title":"Q4","type":"MULTIPLE_CHOICE","points":25,"questionText":"Q4","choices":[{"text":"X","isCorrect":false},{"text":"Y","isCorrect":true}]}')
Q4_ID=$(echo $Q4 | python3 -c "import sys, json; print(json.load(sys.stdin)['_id'])")

# All wrong
ATTEMPT=$(curl -s -b student_cookies.txt -X POST "$BASE_URL/api/quizzes/$QUIZ_ID/attempts")
ATTEMPT_ID=$(echo $ATTEMPT | python3 -c "import sys, json; print(json.load(sys.stdin)['_id'])")
SUBMIT=$(curl -s -b student_cookies.txt -X POST "$BASE_URL/api/attempts/$ATTEMPT_ID/submit" \
  -H "Content-Type: application/json" \
  -d "{\"answers\":[{\"question\":\"$Q1_ID\",\"answer\":\"B\"},{\"question\":\"$Q2_ID\",\"answer\":false},{\"question\":\"$Q3_ID\",\"answer\":\"wrong\"},{\"question\":\"$Q4_ID\",\"answer\":\"X\"}]}")
SCORE=$(echo $SUBMIT | python3 -c "import sys, json; print(json.load(sys.stdin)['score'])")
check_value "0" "$SCORE" "All wrong = 0 pts"

# Partial (2/4 correct)
ATTEMPT=$(curl -s -b student2_cookies.txt -X POST "$BASE_URL/api/quizzes/$QUIZ_ID/attempts")
ATTEMPT_ID=$(echo $ATTEMPT | python3 -c "import sys, json; print(json.load(sys.stdin)['_id'])")
SUBMIT=$(curl -s -b student2_cookies.txt -X POST "$BASE_URL/api/attempts/$ATTEMPT_ID/submit" \
  -H "Content-Type: application/json" \
  -d "{\"answers\":[{\"question\":\"$Q1_ID\",\"answer\":\"A\"},{\"question\":\"$Q2_ID\",\"answer\":false},{\"question\":\"$Q3_ID\",\"answer\":\"correct\"},{\"question\":\"$Q4_ID\",\"answer\":\"X\"}]}")
SCORE=$(echo $SUBMIT | python3 -c "import sys, json; print(json.load(sys.stdin)['score'])")
check_value "50" "$SCORE" "Partial (2/4) = 50 pts"

# Missing answers
ATTEMPT=$(curl -s -b student_cookies.txt -X POST "$BASE_URL/api/quizzes/$QUIZ_ID/attempts")
ATTEMPT_ID=$(echo $ATTEMPT | python3 -c "import sys, json; print(json.load(sys.stdin)['_id'])")
SUBMIT=$(curl -s -b student_cookies.txt -X POST "$BASE_URL/api/attempts/$ATTEMPT_ID/submit" \
  -H "Content-Type: application/json" \
  -d "{\"answers\":[{\"question\":\"$Q1_ID\",\"answer\":\"A\"}]}")
SCORE=$(echo $SUBMIT | python3 -c "import sys, json; print(json.load(sys.stdin)['score'])")
check_value "25" "$SCORE" "Only 1 answer submitted = 25 pts"

# Empty answers array
ATTEMPT=$(curl -s -b student2_cookies.txt -X POST "$BASE_URL/api/quizzes/$QUIZ_ID/attempts")
ATTEMPT_ID=$(echo $ATTEMPT | python3 -c "import sys, json; print(json.load(sys.stdin)['_id'])")
SUBMIT=$(curl -s -b student2_cookies.txt -X POST "$BASE_URL/api/attempts/$ATTEMPT_ID/submit" \
  -H "Content-Type: application/json" \
  -d "{\"answers\":[]}")
SCORE=$(echo $SUBMIT | python3 -c "import sys, json; print(json.load(sys.stdin)['score'])")
check_value "0" "$SCORE" "Empty answers = 0 pts"

curl -s -b faculty_cookies.txt -X DELETE "$BASE_URL/api/quizzes/$QUIZ_ID" > /dev/null
echo ""

#############################################
# SECTION 3: Multiple Attempts
#############################################
echo "=== 3. MULTIPLE ATTEMPTS ==="

QUIZ_RESP=$(curl -s -b faculty_cookies.txt -X POST "$BASE_URL/api/courses/$COURSE_ID/quizzes" \
  -H "Content-Type: application/json" \
  -d '{"title":"Test Quiz - Attempts","published":true,"multipleAttempts":true,"howManyAttempts":3}')
QUIZ_ID=$(echo $QUIZ_RESP | python3 -c "import sys, json; print(json.load(sys.stdin)['_id'])")
echo "[3.1] Created quiz: $QUIZ_ID"

Q1=$(curl -s -b faculty_cookies.txt -X POST "$BASE_URL/api/quizzes/$QUIZ_ID/questions" \
  -H "Content-Type: application/json" \
  -d '{"title":"Q1","type":"MULTIPLE_CHOICE","points":100,"questionText":"Pick A","choices":[{"text":"A","isCorrect":true},{"text":"B","isCorrect":false}]}')
Q1_ID=$(echo $Q1 | python3 -c "import sys, json; print(json.load(sys.stdin)['_id'])")

# Attempt 1
ATTEMPT1=$(curl -s -b student_cookies.txt -X POST "$BASE_URL/api/quizzes/$QUIZ_ID/attempts")
ATTEMPT1_ID=$(echo $ATTEMPT1 | python3 -c "import sys, json; print(json.load(sys.stdin)['_id'])")
ATTEMPT1_NUM=$(echo $ATTEMPT1 | python3 -c "import sys, json; print(json.load(sys.stdin)['attemptNumber'])")
check_value "1" "$ATTEMPT1_NUM" "First attempt = attempt #1"

curl -s -b student_cookies.txt -X POST "$BASE_URL/api/attempts/$ATTEMPT1_ID/submit" \
  -H "Content-Type: application/json" \
  -d "{\"answers\":[{\"question\":\"$Q1_ID\",\"answer\":\"B\"}]}" > /dev/null

# Attempt 2
ATTEMPT2=$(curl -s -b student_cookies.txt -X POST "$BASE_URL/api/quizzes/$QUIZ_ID/attempts")
ATTEMPT2_ID=$(echo $ATTEMPT2 | python3 -c "import sys, json; print(json.load(sys.stdin)['_id'])")
ATTEMPT2_NUM=$(echo $ATTEMPT2 | python3 -c "import sys, json; print(json.load(sys.stdin)['attemptNumber'])")
check_value "2" "$ATTEMPT2_NUM" "Second attempt = attempt #2"

SUBMIT2=$(curl -s -b student_cookies.txt -X POST "$BASE_URL/api/attempts/$ATTEMPT2_ID/submit" \
  -H "Content-Type: application/json" \
  -d "{\"answers\":[{\"question\":\"$Q1_ID\",\"answer\":\"A\"}]}")
SCORE2=$(echo $SUBMIT2 | python3 -c "import sys, json; print(json.load(sys.stdin)['score'])")
check_value "100" "$SCORE2" "Second attempt correct = 100 pts"

# Attempt 3
ATTEMPT3=$(curl -s -b student_cookies.txt -X POST "$BASE_URL/api/quizzes/$QUIZ_ID/attempts")
ATTEMPT3_NUM=$(echo $ATTEMPT3 | python3 -c "import sys, json; print(json.load(sys.stdin)['attemptNumber'])")
check_value "3" "$ATTEMPT3_NUM" "Third attempt = attempt #3"

# Different student has separate attempts
ATTEMPT_S2=$(curl -s -b student2_cookies.txt -X POST "$BASE_URL/api/quizzes/$QUIZ_ID/attempts")
ATTEMPT_S2_NUM=$(echo $ATTEMPT_S2 | python3 -c "import sys, json; print(json.load(sys.stdin)['attemptNumber'])")
check_value "1" "$ATTEMPT_S2_NUM" "Different student starts at attempt #1"

curl -s -b faculty_cookies.txt -X DELETE "$BASE_URL/api/quizzes/$QUIZ_ID" > /dev/null
echo ""

#############################################
# SECTION 4: Permissions
#############################################
echo "=== 4. PERMISSIONS ==="

# Create a quiz for permission tests
QUIZ_RESP=$(curl -s -b faculty_cookies.txt -X POST "$BASE_URL/api/courses/$COURSE_ID/quizzes" \
  -H "Content-Type: application/json" \
  -d '{"title":"Test Quiz - Permissions","published":true}')
QUIZ_ID=$(echo $QUIZ_RESP | python3 -c "import sys, json; print(json.load(sys.stdin)['_id'])")
echo "[4.1] Created quiz: $QUIZ_ID"

# Student tries to create quiz
RESP=$(curl -s -b student_cookies.txt -X POST "$BASE_URL/api/courses/$COURSE_ID/quizzes" \
  -H "Content-Type: application/json" \
  -d '{"title":"Hacker Quiz"}' -w "\n%{http_code}")
HTTP_CODE=$(echo "$RESP" | tail -1)
check_status "403" "$HTTP_CODE" "Student cannot create quiz"

# Student tries to update quiz
RESP=$(curl -s -b student_cookies.txt -X PUT "$BASE_URL/api/quizzes/$QUIZ_ID" \
  -H "Content-Type: application/json" \
  -d '{"title":"Hacked"}' -w "\n%{http_code}")
HTTP_CODE=$(echo "$RESP" | tail -1)
check_status "403" "$HTTP_CODE" "Student cannot update quiz"

# Student tries to delete quiz
RESP=$(curl -s -b student_cookies.txt -X DELETE "$BASE_URL/api/quizzes/$QUIZ_ID" -w "\n%{http_code}")
HTTP_CODE=$(echo "$RESP" | tail -1)
check_status "403" "$HTTP_CODE" "Student cannot delete quiz"

# Student tries to publish quiz
RESP=$(curl -s -b student_cookies.txt -X PUT "$BASE_URL/api/quizzes/$QUIZ_ID/publish" \
  -H "Content-Type: application/json" \
  -d '{"published":false}' -w "\n%{http_code}")
HTTP_CODE=$(echo "$RESP" | tail -1)
check_status "403" "$HTTP_CODE" "Student cannot publish/unpublish quiz"

# Student tries to create question
RESP=$(curl -s -b student_cookies.txt -X POST "$BASE_URL/api/quizzes/$QUIZ_ID/questions" \
  -H "Content-Type: application/json" \
  -d '{"title":"Hacker Q","type":"TRUE_FALSE","points":10}' -w "\n%{http_code}")
HTTP_CODE=$(echo "$RESP" | tail -1)
check_status "403" "$HTTP_CODE" "Student cannot create question"

# Unauthenticated user tries to start attempt
RESP=$(curl -s -X POST "$BASE_URL/api/quizzes/$QUIZ_ID/attempts" -w "\n%{http_code}")
HTTP_CODE=$(echo "$RESP" | tail -1)
check_status "401" "$HTTP_CODE" "Unauthenticated cannot start attempt"

# Unauthenticated user tries to create quiz
RESP=$(curl -s -X POST "$BASE_URL/api/courses/$COURSE_ID/quizzes" \
  -H "Content-Type: application/json" \
  -d '{"title":"Anon Quiz"}' -w "\n%{http_code}")
HTTP_CODE=$(echo "$RESP" | tail -1)
check_status "403" "$HTTP_CODE" "Unauthenticated cannot create quiz"

curl -s -b faculty_cookies.txt -X DELETE "$BASE_URL/api/quizzes/$QUIZ_ID" > /dev/null
echo ""

#############################################
# SECTION 5: Quiz Visibility
#############################################
echo "=== 5. QUIZ VISIBILITY ==="

# Create unpublished quiz
QUIZ_UNPUB=$(curl -s -b faculty_cookies.txt -X POST "$BASE_URL/api/courses/$COURSE_ID/quizzes" \
  -H "Content-Type: application/json" \
  -d '{"title":"Test Quiz - Unpublished","published":false}')
QUIZ_UNPUB_ID=$(echo $QUIZ_UNPUB | python3 -c "import sys, json; print(json.load(sys.stdin)['_id'])")

# Create published quiz
QUIZ_PUB=$(curl -s -b faculty_cookies.txt -X POST "$BASE_URL/api/courses/$COURSE_ID/quizzes" \
  -H "Content-Type: application/json" \
  -d '{"title":"Test Quiz - Published","published":true}')
QUIZ_PUB_ID=$(echo $QUIZ_PUB | python3 -c "import sys, json; print(json.load(sys.stdin)['_id'])")

echo "[5.1] Unpublished: $QUIZ_UNPUB_ID, Published: $QUIZ_PUB_ID"

# Get all quizzes as student
ALL_QUIZZES=$(curl -s -b student_cookies.txt "$BASE_URL/api/courses/$COURSE_ID/quizzes")

# Check if unpublished quiz is in list
HAS_UNPUB=$(echo $ALL_QUIZZES | python3 -c "import sys, json; quizzes=json.load(sys.stdin); print('yes' if any(q['_id']=='$QUIZ_UNPUB_ID' for q in quizzes) else 'no')")
HAS_PUB=$(echo $ALL_QUIZZES | python3 -c "import sys, json; quizzes=json.load(sys.stdin); print('yes' if any(q['_id']=='$QUIZ_PUB_ID' for q in quizzes) else 'no')")

check_value "no" "$HAS_UNPUB" "Student cannot see unpublished quiz"
check_value "yes" "$HAS_PUB" "Student can see published quiz"

# Faculty should see both
FAC_QUIZZES=$(curl -s -b faculty_cookies.txt "$BASE_URL/api/courses/$COURSE_ID/quizzes")
FAC_HAS_UNPUB=$(echo $FAC_QUIZZES | python3 -c "import sys, json; quizzes=json.load(sys.stdin); print('yes' if any(q['_id']=='$QUIZ_UNPUB_ID' for q in quizzes) else 'no')")
check_value "yes" "$FAC_HAS_UNPUB" "Faculty can see unpublished quiz"

curl -s -b faculty_cookies.txt -X DELETE "$BASE_URL/api/quizzes/$QUIZ_UNPUB_ID" > /dev/null
curl -s -b faculty_cookies.txt -X DELETE "$BASE_URL/api/quizzes/$QUIZ_PUB_ID" > /dev/null
echo ""

#############################################
# SECTION 5b: Attempt Limits
#############################################
echo "=== 5b. ATTEMPT LIMITS ==="

QUIZ_RESP=$(curl -s -b faculty_cookies.txt -X POST "$BASE_URL/api/courses/$COURSE_ID/quizzes" \
  -H "Content-Type: application/json" \
  -d '{"title":"Test Quiz - Limited","published":true,"howManyAttempts":2}')
QUIZ_ID=$(echo $QUIZ_RESP | python3 -c "import sys, json; print(json.load(sys.stdin)['_id'])")
echo "[5b.1] Created quiz with 2 attempt limit: $QUIZ_ID"

Q1=$(curl -s -b faculty_cookies.txt -X POST "$BASE_URL/api/quizzes/$QUIZ_ID/questions" \
  -H "Content-Type: application/json" \
  -d '{"title":"Q1","type":"TRUE_FALSE","points":10,"questionText":"Test","correctAnswer":true}')
Q1_ID=$(echo $Q1 | python3 -c "import sys, json; print(json.load(sys.stdin)['_id'])")

# Attempt 1
ATTEMPT1=$(curl -s -b student_cookies.txt -X POST "$BASE_URL/api/quizzes/$QUIZ_ID/attempts")
ATTEMPT1_ID=$(echo $ATTEMPT1 | python3 -c "import sys, json; print(json.load(sys.stdin)['_id'])")
curl -s -b student_cookies.txt -X POST "$BASE_URL/api/attempts/$ATTEMPT1_ID/submit" \
  -H "Content-Type: application/json" \
  -d "{\"answers\":[{\"question\":\"$Q1_ID\",\"answer\":true}]}" > /dev/null

# Attempt 2
ATTEMPT2=$(curl -s -b student_cookies.txt -X POST "$BASE_URL/api/quizzes/$QUIZ_ID/attempts")
ATTEMPT2_ID=$(echo $ATTEMPT2 | python3 -c "import sys, json; print(json.load(sys.stdin)['_id'])")
curl -s -b student_cookies.txt -X POST "$BASE_URL/api/attempts/$ATTEMPT2_ID/submit" \
  -H "Content-Type: application/json" \
  -d "{\"answers\":[{\"question\":\"$Q1_ID\",\"answer\":true}]}" > /dev/null

# Attempt 3 should fail
ATTEMPT3_RESP=$(curl -s -b student_cookies.txt -X POST "$BASE_URL/api/quizzes/$QUIZ_ID/attempts" -w "\n%{http_code}")
HTTP_CODE=$(echo "$ATTEMPT3_RESP" | tail -1)
check_status "403" "$HTTP_CODE" "Third attempt blocked (limit is 2)"

curl -s -b faculty_cookies.txt -X DELETE "$BASE_URL/api/quizzes/$QUIZ_ID" > /dev/null
echo ""

#############################################
# SECTION 6: Edge Cases
#############################################
echo "=== 6. EDGE CASES ==="

# Quiz with no questions
QUIZ_EMPTY=$(curl -s -b faculty_cookies.txt -X POST "$BASE_URL/api/courses/$COURSE_ID/quizzes" \
  -H "Content-Type: application/json" \
  -d '{"title":"Test Quiz - Empty","published":true}')
QUIZ_EMPTY_ID=$(echo $QUIZ_EMPTY | python3 -c "import sys, json; print(json.load(sys.stdin)['_id'])")
echo "[6.1] Empty quiz: $QUIZ_EMPTY_ID"

ATTEMPT=$(curl -s -b student_cookies.txt -X POST "$BASE_URL/api/quizzes/$QUIZ_EMPTY_ID/attempts")
ATTEMPT_ID=$(echo $ATTEMPT | python3 -c "import sys, json; print(json.load(sys.stdin)['_id'])")
SUBMIT=$(curl -s -b student_cookies.txt -X POST "$BASE_URL/api/attempts/$ATTEMPT_ID/submit" \
  -H "Content-Type: application/json" \
  -d '{"answers":[]}')
SCORE=$(echo $SUBMIT | python3 -c "import sys, json; print(json.load(sys.stdin)['score'])")
check_value "0" "$SCORE" "Empty quiz submission = 0 pts"

curl -s -b faculty_cookies.txt -X DELETE "$BASE_URL/api/quizzes/$QUIZ_EMPTY_ID" > /dev/null

# Submit with invalid question ID
QUIZ_RESP=$(curl -s -b faculty_cookies.txt -X POST "$BASE_URL/api/courses/$COURSE_ID/quizzes" \
  -H "Content-Type: application/json" \
  -d '{"title":"Test Quiz - Invalid","published":true}')
QUIZ_ID=$(echo $QUIZ_RESP | python3 -c "import sys, json; print(json.load(sys.stdin)['_id'])")

Q1=$(curl -s -b faculty_cookies.txt -X POST "$BASE_URL/api/quizzes/$QUIZ_ID/questions" \
  -H "Content-Type: application/json" \
  -d '{"title":"Q1","type":"TRUE_FALSE","points":10,"questionText":"Test","correctAnswer":true}')
Q1_ID=$(echo $Q1 | python3 -c "import sys, json; print(json.load(sys.stdin)['_id'])")

ATTEMPT=$(curl -s -b student_cookies.txt -X POST "$BASE_URL/api/quizzes/$QUIZ_ID/attempts")
ATTEMPT_ID=$(echo $ATTEMPT | python3 -c "import sys, json; print(json.load(sys.stdin)['_id'])")
SUBMIT=$(curl -s -b student_cookies.txt -X POST "$BASE_URL/api/attempts/$ATTEMPT_ID/submit" \
  -H "Content-Type: application/json" \
  -d '{"answers":[{"question":"000000000000000000000000","answer":true}]}')
SCORE=$(echo $SUBMIT | python3 -c "import sys, json; print(json.load(sys.stdin)['score'])")
check_value "0" "$SCORE" "Invalid question ID ignored = 0 pts"

curl -s -b faculty_cookies.txt -X DELETE "$BASE_URL/api/quizzes/$QUIZ_ID" > /dev/null
echo ""

#############################################
# Cleanup
#############################################
echo "[CLEANUP] Removing test data..."
rm -f faculty_cookies.txt student_cookies.txt student2_cookies.txt anon_cookies.txt
mongosh --quiet kanbas --eval "db.users.deleteMany({username: /^test_/})" > /dev/null

echo ""
echo "========================================="
echo "RESULTS: $PASS passed, $FAIL failed"
echo "========================================="

if [ $FAIL -gt 0 ]; then
  exit 1
fi
