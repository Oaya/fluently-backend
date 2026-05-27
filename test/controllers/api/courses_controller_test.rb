require "test_helper"

class Api::CoursesControllerTest < ActionDispatch::IntegrationTest
  include TestDataHelper

  def sign_in_as(user)
    post "/api/auth/users/sign_in",
      params: { api_user: { email: user.email, password: "password123" } },
      as: :json
    response.headers["Authorization"]
  end

  def create_admin(tenant:)
    user = create_user(tenant: tenant)
    Membership.create!(user: user, tenant: tenant, role: "admin")
    user
  end

  def create_student(tenant:)
    user = create_user(tenant: tenant)
    Membership.create!(user: user, tenant: tenant, role: "student")
    user
  end

  # --- index ---

  test "index returns 401 when unauthenticated" do
    get "/api/courses", as: :json
    assert_response :unauthorized
  end

  test "index returns 200 and list of courses for authenticated user" do
    tenant = create_tenant
    admin = create_admin(tenant: tenant)
    course = create_course(tenant: tenant)
    token = sign_in_as(admin)

    get "/api/courses", headers: { "Authorization" => token }, as: :json

    assert_response :ok
    ids = JSON.parse(response.body).map { |c| c["id"] }
    assert_includes ids, course.id
  end

  test "index only returns courses scoped to current tenant" do
    tenant = create_tenant
    admin = create_admin(tenant: tenant)
    course = create_course(tenant: tenant)
    token = sign_in_as(admin)

    other_tenant = create_tenant
    other_course = create_course(tenant: other_tenant)

    get "/api/courses", headers: { "Authorization" => token }, as: :json

    assert_response :ok
    ids = JSON.parse(response.body).map { |c| c["id"] }
    assert_includes ids, course.id
    assert_not_includes ids, other_course.id
  end

  # --- show ---

  test "show returns 401 when unauthenticated" do
    tenant = create_tenant
    course = create_course(tenant: tenant)

    get "/api/courses/#{course.id}", as: :json
    assert_response :unauthorized
  end

  test "show returns 200 and the correct course" do
    tenant = create_tenant
    admin = create_admin(tenant: tenant)
    course = create_course(tenant: tenant)
    token = sign_in_as(admin)

    get "/api/courses/#{course.id}", headers: { "Authorization" => token }, as: :json

    assert_response :ok
    assert_equal course.id, JSON.parse(response.body)["id"]
  end

  test "show returns 404 for a course belonging to another tenant" do
    tenant = create_tenant
    admin = create_admin(tenant: tenant)
    token = sign_in_as(admin)

    other_tenant = create_tenant
    other_course = create_course(tenant: other_tenant)

    get "/api/courses/#{other_course.id}", headers: { "Authorization" => token }, as: :json
    assert_response :not_found
  end

  # --- overview ---

  test "overview returns 401 when unauthenticated" do
    tenant = create_tenant
    course = create_course(tenant: tenant)

    get "/api/courses/#{course.id}/overview", as: :json
    assert_response :unauthorized
  end

  test "overview returns 200 with sections and lessons" do
    tenant = create_tenant
    admin = create_admin(tenant: tenant)
    course = create_course(tenant: tenant)
    section = create_section(tenant: tenant, course: course)
    create_lesson(tenant: tenant, section: section)
    token = sign_in_as(admin)

    get "/api/courses/#{course.id}/overview", headers: { "Authorization" => token }, as: :json

    assert_response :ok
    body = JSON.parse(response.body)
    assert_equal course.id, body["id"]
    assert_equal 1, body["sections"].size
    assert_equal 1, body["sections"].first["lessons"].size
  end

  # --- create ---

  test "create returns 401 when unauthenticated" do
    post "/api/courses", params: { title: "Test", description: "Desc" }, as: :json
    assert_response :unauthorized
  end

  test "create returns 403 when user is a student" do
    tenant = create_tenant
    student = create_student(tenant: tenant)
    token = sign_in_as(student)

    post "/api/courses",
      params: { title: "Test", description: "Desc" },
      headers: { "Authorization" => token },
      as: :json

    assert_response :forbidden
  end

  test "create returns 402 when tenant is not active" do
    tenant = create_tenant(status: "past_due")
    admin = create_admin(tenant: tenant)
    token = sign_in_as(admin)

    post "/api/courses",
      params: { title: "Test", description: "Desc" },
      headers: { "Authorization" => token },
      as: :json

    assert_response :payment_required
  end

  test "create returns 201 and creates the course with valid params" do
    tenant = create_tenant
    admin = create_admin(tenant: tenant)
    token = sign_in_as(admin)

    post "/api/courses",
      params: { title: "New Course", description: "A description" },
      headers: { "Authorization" => token },
      as: :json

    assert_response :created
    assert_equal "New Course", JSON.parse(response.body)["title"]
  end

  test "create returns 422 when title is blank" do
    tenant = create_tenant
    admin = create_admin(tenant: tenant)
    token = sign_in_as(admin)

    post "/api/courses",
      params: { title: "", description: "A description" },
      headers: { "Authorization" => token },
      as: :json

    assert_response :unprocessable_entity
    assert JSON.parse(response.body)["error"].present?
  end

  # --- update ---

  test "update returns 401 when unauthenticated" do
    tenant = create_tenant
    course = create_course(tenant: tenant)

    patch "/api/courses/#{course.id}", params: { title: "Updated" }, as: :json
    assert_response :unauthorized
  end

  test "update returns 403 when user is a student" do
    tenant = create_tenant
    student = create_student(tenant: tenant)
    course = create_course(tenant: tenant)
    token = sign_in_as(student)

    patch "/api/courses/#{course.id}",
      params: { title: "Updated" },
      headers: { "Authorization" => token },
      as: :json

    assert_response :forbidden
  end

  test "update returns 402 when tenant is not active" do
    tenant = create_tenant(status: "past_due")
    admin = create_admin(tenant: tenant)
    course = create_course(tenant: tenant)
    token = sign_in_as(admin)

    patch "/api/courses/#{course.id}",
      params: { title: "Updated" },
      headers: { "Authorization" => token },
      as: :json

    assert_response :payment_required
  end

  test "update returns 200 and updates the course" do
    tenant = create_tenant
    admin = create_admin(tenant: tenant)
    course = create_course(tenant: tenant)
    token = sign_in_as(admin)

    patch "/api/courses/#{course.id}",
      params: { title: "Updated Title" },
      headers: { "Authorization" => token },
      as: :json

    assert_response :ok
    assert_equal "Updated Title", JSON.parse(response.body)["title"]
  end

  test "update returns 422 when price is negative" do
    tenant = create_tenant
    admin = create_admin(tenant: tenant)
    course = create_course(tenant: tenant)
    token = sign_in_as(admin)

    patch "/api/courses/#{course.id}",
      params: { price: -1 },
      headers: { "Authorization" => token },
      as: :json

    assert_response :unprocessable_entity
    assert JSON.parse(response.body)["error"].present?
  end

  test "update returns 404 for a course belonging to another tenant" do
    tenant = create_tenant
    admin = create_admin(tenant: tenant)
    token = sign_in_as(admin)

    other_tenant = create_tenant
    other_course = create_course(tenant: other_tenant)

    patch "/api/courses/#{other_course.id}",
      params: { title: "Updated" },
      headers: { "Authorization" => token },
      as: :json

    assert_response :not_found
  end

  # --- destroy ---

  test "destroy returns 401 when unauthenticated" do
    tenant = create_tenant
    course = create_course(tenant: tenant)

    delete "/api/courses/#{course.id}", as: :json
    assert_response :unauthorized
  end

  test "destroy returns 403 when user is a student" do
    tenant = create_tenant
    student = create_student(tenant: tenant)
    course = create_course(tenant: tenant)
    token = sign_in_as(student)

    delete "/api/courses/#{course.id}",
      headers: { "Authorization" => token },
      as: :json

    assert_response :forbidden
  end

  test "destroy returns 402 when tenant is not active" do
    tenant = create_tenant(status: "past_due")
    admin = create_admin(tenant: tenant)
    course = create_course(tenant: tenant)
    token = sign_in_as(admin)

    delete "/api/courses/#{course.id}",
      headers: { "Authorization" => token },
      as: :json

    assert_response :payment_required
  end

  test "destroy returns 200 and deletes the course" do
    tenant = create_tenant
    admin = create_admin(tenant: tenant)
    course = create_course(tenant: tenant)
    token = sign_in_as(admin)

    delete "/api/courses/#{course.id}",
      headers: { "Authorization" => token },
      as: :json

    assert_response :ok
    assert_not Course.exists?(course.id)
  end

  test "destroy returns 404 for a course belonging to another tenant" do
    tenant = create_tenant
    admin = create_admin(tenant: tenant)
    token = sign_in_as(admin)

    other_tenant = create_tenant
    other_course = create_course(tenant: other_tenant)

    delete "/api/courses/#{other_course.id}",
      headers: { "Authorization" => token },
      as: :json

    assert_response :not_found
  end

  # --- price ---

  test "price returns 401 when unauthenticated" do
    tenant = create_tenant
    course = create_course(tenant: tenant)

    patch "/api/courses/#{course.id}/price", params: { price: 29.99 }, as: :json
    assert_response :unauthorized
  end

  test "price returns 403 when user is a student" do
    tenant = create_tenant
    student = create_student(tenant: tenant)
    course = create_course(tenant: tenant)
    token = sign_in_as(student)

    patch "/api/courses/#{course.id}/price",
      params: { price: 29.99 },
      headers: { "Authorization" => token },
      as: :json

    assert_response :forbidden
  end

  test "price returns 201 and updates the course price" do
    tenant = create_tenant
    admin = create_admin(tenant: tenant)
    course = create_course(tenant: tenant)
    token = sign_in_as(admin)

    patch "/api/courses/#{course.id}/price",
      params: { price: 49.99 },
      headers: { "Authorization" => token },
      as: :json

    assert_response :created
    assert_equal 49.99, JSON.parse(response.body)["price"].to_f
  end

  # --- publish ---

  test "publish returns 401 when unauthenticated" do
    tenant = create_tenant
    course = create_course(tenant: tenant)

    patch "/api/courses/#{course.id}/publish", as: :json
    assert_response :unauthorized
  end

  test "publish returns 403 when user is a student" do
    tenant = create_tenant
    student = create_student(tenant: tenant)
    course = create_course(tenant: tenant)
    token = sign_in_as(student)

    patch "/api/courses/#{course.id}/publish",
      headers: { "Authorization" => token },
      as: :json

    assert_response :forbidden
  end

  test "publish returns 201 and marks the course as published" do
    tenant = create_tenant
    admin = create_admin(tenant: tenant)
    course = create_course(tenant: tenant)
    token = sign_in_as(admin)

    patch "/api/courses/#{course.id}/publish",
      headers: { "Authorization" => token },
      as: :json

    assert_response :created
    assert course.reload.published
  end
end
