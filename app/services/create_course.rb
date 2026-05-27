class CreateCourse
  def initialize(tenant:, params:)
    @tenant = tenant
    @course_data = params.except(:instructor_ids)
    @instructor_ids = params[:instructor_ids] || []
    @signed_id =  params[:thumbnail_signed_id].to_s
  end

  def call
    @course = @tenant.courses.new(@course_data)
    max = @tenant.plan.features["max_courses"]

    # nil => unlimited
    if max && @tenant.courses.count >= max
      course.errors.add(:base, "Your plan allows only #{max} courses")
      return course
    end

    @course.save

    instructors = sync_instructors

    handle_thumbnail

    # return the course and instructors
    return @course, instructors
  end

  private

  def sync_instructors
    instructors = User.where(id: @instructor_ids, tenant_id: @tenant.id)
    instructors.each { |instructor|   CourseInstructor.find_or_create_by(course: @course, instructor: instructor) }
    instructors
  end

  def handle_thumbnail
    @course.thumbnail.attach(@signed_id) if @signed_id.present?
  end
end
