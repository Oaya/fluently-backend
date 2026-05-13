require "test_helper"

class CourseTest < ActiveSupport::TestCase
  include TestDataHelper

  # --- Validations ---

  test "is valid with valid attributes" do
    tenant = create_tenant
    course = Course.new(tenant: tenant, title: "My Course", description: "A great course")
    assert course.valid?
  end

  test "requires title on create" do
    tenant = create_tenant
    course = Course.new(tenant: tenant, description: "A great course")
    assert_not course.valid?
    assert_includes course.errors[:title], "can't be blank"
  end

  test "requires description on create" do
    tenant = create_tenant
    course = Course.new(tenant: tenant, title: "My Course")
    assert_not course.valid?
    assert_includes course.errors[:description], "can't be blank"
  end

  test "requires tenant" do
    course = Course.new(title: "My Course", description: "A great course")
    assert_not course.valid?
    assert course.errors[:tenant].any? || course.errors[:tenant_id].any?
  end

  test "allows nil price" do
    tenant = create_tenant
    course = Course.new(tenant: tenant, title: "My Course", description: "Desc", price: nil)
    assert course.valid?
  end

  test "allows zero price" do
    tenant = create_tenant
    course = Course.new(tenant: tenant, title: "My Course", description: "Desc", price: 0)
    assert course.valid?
  end

  test "allows positive price" do
    tenant = create_tenant
    course = Course.new(tenant: tenant, title: "My Course", description: "Desc", price: 49.99)
    assert course.valid?
  end

  test "rejects negative price" do
    tenant = create_tenant
    course = Course.new(tenant: tenant, title: "My Course", description: "Desc", price: -1)
    assert_not course.valid?
    assert course.errors[:price].any?
  end

  test "title and description not required on update" do
    tenant = create_tenant
    course = create_course(tenant: tenant)
    course.title = nil
    course.description = nil
    assert course.valid?
  end

  # --- Enums ---

  test "accepts valid category values" do
    tenant = create_tenant
    Course.categories.each_key do |cat|
      course = Course.new(tenant: tenant, title: "Course", description: "Desc", category: cat)
      assert course.valid?, "Expected category '#{cat}' to be valid"
    end
  end

  test "rejects invalid category" do
    tenant = create_tenant
    assert_raises(ArgumentError) do
      Course.new(tenant: tenant, title: "Course", description: "Desc", category: "invalid_category")
    end
  end

  test "accepts valid level values" do
    tenant = create_tenant
    Course.levels.each_key do |lvl|
      course = Course.new(tenant: tenant, title: "Course", description: "Desc", level: lvl)
      assert course.valid?, "Expected level '#{lvl}' to be valid"
    end
  end

  test "rejects invalid level" do
    tenant = create_tenant
    assert_raises(ArgumentError) do
      Course.new(tenant: tenant, title: "Course", description: "Desc", level: "expert")
    end
  end

  # --- Associations ---

  test "destroying course destroys its sections" do
    tenant = create_tenant
    course = create_course(tenant: tenant)
    create_section(tenant: tenant, course: course)
    assert_difference "Section.count", -1 do
      course.destroy
    end
  end

  test "destroying course destroys its course_instructors" do
    tenant = create_tenant
    course = create_course(tenant: tenant)
    instructor = create_user(tenant: tenant, email: "inst-#{SecureRandom.hex(4)}@example.com")
    CourseInstructor.create!(course: course, instructor: instructor)
    assert_difference "CourseInstructor.count", -1 do
      course.destroy
    end
  end
end
