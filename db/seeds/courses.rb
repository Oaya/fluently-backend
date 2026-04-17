tenant = Tenant.find_by!(name: "Test Tenant")
instructor = tenant.users.joins(:membership).where(memberships: { role: "instructor" }).first

courses_data = [
  {
    title: "Ruby on Rails for Beginners",
    description: "Learn Ruby on Rails from scratch and build real web applications.",
    category: "development",
    level: "beginner",
    price: 29.99,
    published: true,
    sections: [
      {
        title: "Getting Started",
        description: "Set up your development environment and understand the basics.",
        lessons: [
          { title: "Introduction to Rails", lesson_type: "reading", article: "Rails is a web application framework running on the Ruby programming language." },
          { title: "Installing Ruby and Rails", lesson_type: "reading", article: "Follow these steps to install Ruby and Rails on your machine." },
          { title: "Your First Rails App", lesson_type: "reading", article: "Generate your first Rails application using the rails new command." }
        ]
      },
      {
        title: "MVC Architecture",
        description: "Understand Models, Views, and Controllers.",
        lessons: [
          { title: "What is MVC?", lesson_type: "reading", article: "MVC separates your application into three interconnected components." },
          { title: "Creating Models", lesson_type: "reading", article: "Models represent your data and business logic." },
          { title: "Building Controllers", lesson_type: "reading", article: "Controllers handle requests and coordinate between models and views." }
        ]
      }
    ]
  },
  {
    title: "React Fundamentals",
    description: "Master React and build modern, interactive user interfaces.",
    category: "development",
    level: "intermediate",
    price: 49.99,
    published: true,
    sections: [
      {
        title: "React Basics",
        description: "Learn the core concepts of React.",
        lessons: [
          { title: "What is React?", lesson_type: "reading", article: "React is a JavaScript library for building user interfaces." },
          { title: "JSX Syntax", lesson_type: "reading", article: "JSX allows you to write HTML-like syntax in JavaScript." }
        ]
      },
      {
        title: "Hooks and State",
        description: "Manage component state and side effects with hooks.",
        lessons: [
          { title: "useState Hook", lesson_type: "reading", article: "useState lets you add state to functional components." },
          { title: "useEffect Hook", lesson_type: "reading", article: "useEffect lets you perform side effects in functional components." },
          { title: "Custom Hooks", lesson_type: "reading", article: "Extract reusable logic into custom hooks." }
        ]
      }
    ]
  },
  {
    title: "Introduction to UI/UX Design",
    description: "Learn the principles of great user experience and interface design.",
    category: "design",
    level: "all_levels",
    price: 19.99,
    published: false,
    sections: [
      {
        title: "Design Principles",
        description: "Core principles every designer should know.",
        lessons: [
          { title: "Color Theory", lesson_type: "reading", article: "Color theory helps designers make effective color choices." },
          { title: "Typography Basics", lesson_type: "reading", article: "Typography is the art of arranging text to make it readable and appealing." }
        ]
      }
    ]
  }
]

courses_data.each do |course_data|
  sections_data = course_data.delete(:sections)

  course = tenant.courses.create!(course_data)
  CourseInstructor.create!(course: course, instructor: instructor) if instructor

  sections_data.each_with_index do |section_data, section_index|
    lessons_data = section_data.delete(:lessons)

    section = Section.create!(
      **section_data,
      course: course,
      tenant: tenant,
      position: section_index + 1
    )

    lessons_data.each do |lesson_data|
      Lesson.create!(
        **lesson_data,
        section: section,
        tenant: tenant
      )
    end
  end
end

pp "Created #{Course.count} courses with sections and lessons for tenant #{tenant.name}"
