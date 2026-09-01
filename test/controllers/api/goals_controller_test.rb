require "test_helper"

class Api::GoalsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = create_admin
    @student = create_student(admin: @admin)
    @other_admin = create_admin
    @other_student = create_student(admin: @other_admin)
    @goal = create_goal(admin: @admin, student: @student)
  end

  # --- index ---

  test "index returns the admin's own students' goals" do
    other_goal = create_goal(admin: @other_admin, student: @other_student)

    get api_goals_url, headers: auth_header(@admin)
    assert_response :success

    ids = response.parsed_body.map { |g| g["id"] }
    assert_includes ids, @goal.id
    assert_not_includes ids, other_goal.id
  end

  test "index returns only the student's own goals" do
    get api_goals_url, headers: auth_header(@student)
    assert_response :success

    ids = response.parsed_body.map { |g| g["id"] }
    assert_equal [ @goal.id ], ids
  end

  # --- show ---

  test "show allows the owning admin" do
    get api_goal_url(@goal), headers: auth_header(@admin)
    assert_response :success
    assert_equal @goal.id, response.parsed_body["id"]
  end

  test "show allows the owning student" do
    get api_goal_url(@goal), headers: auth_header(@student)
    assert_response :success
  end

  test "show is not found for a different admin" do
    get api_goal_url(@goal), headers: auth_header(@other_admin)
    assert_response :not_found
  end

  # --- create ---

  test "create builds a goal for the student themself" do
    assert_difference "Goal.count", 1 do
      post api_goals_url, params: { goal: { title: "Goal", target_date: 1.month.from_now.to_date } }, headers: auth_header(@student)
    end
    assert_response :created
    assert_equal @student.id, response.parsed_body["student_id"]
  end

  test "create builds a goal for the admin's own student" do
    assert_difference "Goal.count", 1 do
      post api_goals_url, params: { goal: { student_id: @student.id, title: "New Goal", target_date: 1.month.from_now.to_date } }, headers: auth_header(@admin)
    end
    assert_response :created
    assert_equal "New Goal", response.parsed_body["title"]
  end

  test "create rejects a student that does not belong to the admin" do
    post api_goals_url, params: { goal: { student_id: @other_student.id, title: "Goal", target_date: 1.month.from_now.to_date } }, headers: auth_header(@admin)
    assert_response :not_found
  end

  test "create returns validation errors" do
    post api_goals_url, params: { goal: { student_id: @student.id, title: "" } }, headers: auth_header(@admin)
    assert_response :unprocessable_entity
  end

  # --- update ---

  test "update modifies the goal for the owning student" do
    patch api_goal_url(@goal), params: { goal: { title: "Updated" } }, headers: auth_header(@student)
    assert_response :success
    assert_equal "Updated", @goal.reload.title
  end

  test "update modifies the goal" do
    patch api_goal_url(@goal), params: { goal: { title: "Updated" } }, headers: auth_header(@admin)
    assert_response :success
    assert_equal "Updated", @goal.reload.title
  end

  # --- destroy ---

  test "destroy removes the goal for the owning student" do
    assert_difference "Goal.count", -1 do
      delete api_goal_url(@goal), headers: auth_header(@student)
    end
    assert_response :no_content
  end

  test "destroy removes a goal that has activities and comments" do
    @goal.goal_activities.create!(admin: @admin, student: @student, description: "did stuff", date: Date.today, progress: 50)
    @goal.goal_comments.create!(admin: @admin, comment: "nice")

    assert_difference "Goal.count", -1 do
      delete api_goal_url(@goal), headers: auth_header(@admin)
    end
    assert_response :no_content
  end

  # --- activity ---

  test "activity is forbidden for admins" do
    post activity_api_goal_url(@goal), params: { date: Date.today, description: "did stuff", progress: 50 }, headers: auth_header(@admin)
    assert_response :forbidden
  end

  test "activity creates a goal activity and updates goal progress" do
    assert_difference "GoalActivity.count", 1 do
      post activity_api_goal_url(@goal), params: { date: Date.today, description: "did stuff", progress: 50, status: "in_progress" }, headers: auth_header(@student)
    end
    assert_response :created
    assert_equal "in_progress", @goal.reload.status
    assert_equal 50, @goal.progress
  end

  test "update_activity edits an existing activity" do
    activity = @goal.goal_activities.create!(admin: @admin, student: @student, description: "old", date: Date.today, progress: 10)

    patch activity_api_goal_url(@goal), params: { activity_id: activity.id, description: "new", progress: 80, status: "in_progress" }, headers: auth_header(@student)
    assert_response :success
    assert_equal "new", activity.reload.description
    assert_equal 80, @goal.reload.progress
  end

  test "update_activity returns not found for an unknown activity" do
    patch activity_api_goal_url(@goal), params: { activity_id: SecureRandom.uuid, description: "new" }, headers: auth_header(@student)
    assert_response :not_found
  end

  test "destroy_activity removes the activity and recomputes goal progress" do
    older = @goal.goal_activities.create!(admin: @admin, student: @student, description: "first", date: 2.days.ago.to_date, progress: 30)
    newer = @goal.goal_activities.create!(admin: @admin, student: @student, description: "second", date: 1.day.ago.to_date, progress: 100)

    assert_difference "GoalActivity.count", -1 do
      delete destroy_activity_api_goal_url(@goal, activity_id: newer.id), headers: auth_header(@student)
    end
    assert_response :no_content
    assert_equal 30, @goal.reload.progress
    assert_equal "in_progress", @goal.status
  end

  test "destroy_activity returns not found for an unknown activity" do
    delete destroy_activity_api_goal_url(@goal, activity_id: SecureRandom.uuid), headers: auth_header(@student)
    assert_response :not_found
  end

  # --- comment ---

  test "comment is forbidden for students" do
    post comment_api_goal_url(@goal), params: { comment: "great job" }, headers: auth_header(@student)
    assert_response :forbidden
  end

  test "comment adds a comment from the admin" do
    assert_difference "GoalComment.count", 1 do
      post comment_api_goal_url(@goal), params: { comment: "great job" }, headers: auth_header(@admin)
    end
    assert_response :created
  end

  test "destroy_comment removes a comment" do
    comment = @goal.goal_comments.create!(admin: @admin, comment: "great job")

    assert_difference "GoalComment.count", -1 do
      delete destroy_comment_api_goal_url(@goal, comment_id: comment.id), headers: auth_header(@admin)
    end
    assert_response :success
  end

  test "destroy_comment returns not found for an unknown comment" do
    delete destroy_comment_api_goal_url(@goal, comment_id: SecureRandom.uuid), headers: auth_header(@admin)
    assert_response :not_found
  end
end
