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
          {
            title: "Introduction to Rails",
            lesson_type: "reading",
            duration_in_seconds: 480,
            article: <<~ARTICLE
              Ruby on Rails is a full-stack web application framework written in Ruby. Created by David Heinemeier Hansson and released in 2004, Rails follows two core principles: Convention over Configuration (CoC) and Don't Repeat Yourself (DRY).

              Convention over Configuration means that Rails makes assumptions about what you want to do and how you want to do it, rather than requiring you to specify every little thing. This dramatically reduces the amount of code you have to write to get a working application.

              The DRY principle encourages you to write logic once and reuse it, keeping your codebase clean and maintainable. Rails bakes this into its architecture through helpers, concerns, and shared partials.

              Rails uses the MVC (Model-View-Controller) pattern to separate your application into distinct responsibilities. Models manage data and business rules, Views handle presentation, and Controllers act as the glue that ties the two together.

              Beyond MVC, Rails ships with a powerful ORM called ActiveRecord, a templating engine called ERB, a routing DSL, built-in test support, asset pipeline management, and a rich ecosystem of gems (libraries). This makes it one of the most productive frameworks for building database-backed web applications.

              Companies like GitHub, Shopify, Basecamp, and Airbnb have all used Rails to ship production applications, a testament to the framework's scalability and developer productivity.
            ARTICLE
          },
          {
            title: "Installing Ruby and Rails",
            lesson_type: "reading",
            duration_in_seconds: 600,
            article: <<~ARTICLE
              Before you can build a Rails application, you need to install Ruby and Rails on your machine. The recommended approach differs slightly depending on your operating system.

              **macOS**
              The easiest way to manage Ruby versions on macOS is with a version manager like `rbenv` or `rvm`. Install Homebrew first (https://brew.sh), then run:

              ```
              brew install rbenv
              rbenv install 3.3.0
              rbenv global 3.3.0
              ```

              Once Ruby is installed, install the Rails gem:
              ```
              gem install rails
              ```

              **Linux (Ubuntu/Debian)**
              Use `rbenv` or `rvm` similarly. First install the build dependencies:
              ```
              sudo apt-get install -y build-essential libssl-dev libreadline-dev zlib1g-dev
              ```
              Then install rbenv and Ruby as above.

              **Windows**
              The recommended approach is to use WSL2 (Windows Subsystem for Linux) and follow the Linux instructions. Alternatively, RubyInstaller (https://rubyinstaller.org) provides a native Windows installation.

              **Verifying Your Installation**
              Run the following commands to confirm everything is set up correctly:
              ```
              ruby -v    # should print Ruby 3.x.x
              rails -v   # should print Rails 7.x.x
              ```

              You will also need Node.js and Yarn (or Bun) for the JavaScript asset pipeline, and SQLite3 (or PostgreSQL/MySQL) for the database. Most development setups use SQLite3 because it requires zero configuration.
            ARTICLE
          },
          {
            title: "Your First Rails App",
            lesson_type: "reading",
            duration_in_seconds: 720,
            article: <<~ARTICLE
              Creating your first Rails application is as simple as running a single command. Open your terminal and navigate to the directory where you want to create the project:

              ```
              rails new my_app --database=sqlite3
              cd my_app
              ```

              Rails will generate a complete directory structure and install all required gems automatically. Here is a quick tour of the most important directories:

              - `app/` — the heart of your application. Contains models, views, controllers, helpers, mailers, jobs, and channels.
              - `config/` — configuration files including `routes.rb`, `database.yml`, and environment-specific settings.
              - `db/` — database schema and migration files.
              - `Gemfile` — lists all the Ruby gems your project depends on.
              - `public/` — static files served directly by the web server.
              - `test/` (or `spec/` if you choose RSpec) — automated tests.

              **Starting the Development Server**
              ```
              bin/rails server
              ```
              Visit `http://localhost:3000` in your browser. You should see the Rails welcome page.

              **Generating a Resource**
              Rails provides generators to scaffold common patterns quickly:
              ```
              bin/rails generate scaffold Post title:string body:text published:boolean
              bin/rails db:migrate
              ```

              This creates the model, migration, controller, views, and routes for a `Post` resource all at once. Visit `http://localhost:3000/posts` to see the generated CRUD interface.

              From here you can customise the generated code to match your specific requirements. This scaffold gives you a solid starting point that you can iterate on rather than writing everything from scratch.
            ARTICLE
          }
        ]
      },
      {
        title: "MVC Architecture",
        description: "Understand Models, Views, and Controllers.",
        lessons: [
          {
            title: "What is MVC?",
            lesson_type: "reading",
            duration_in_seconds: 540,
            article: <<~ARTICLE
              MVC stands for Model-View-Controller. It is a software architectural pattern that separates an application into three interconnected components, each with a distinct responsibility. Rails enforces this separation strictly, which keeps large codebases organised and maintainable.

              **Model**
              The Model is responsible for the data layer of your application. It communicates with the database, enforces business rules, and validates data. In Rails, models inherit from `ActiveRecord::Base` (or `ApplicationRecord` in modern Rails), giving them a powerful set of database-interaction methods out of the box.

              **View**
              The View is responsible for presenting data to the user. In Rails, views are typically ERB templates (`.html.erb` files) that mix HTML with embedded Ruby code. Views should contain as little logic as possible — their job is display, not computation.

              **Controller**
              The Controller sits between the Model and the View. It receives an HTTP request, asks the appropriate model(s) for data, and passes that data to a view to render a response. Controllers in Rails inherit from `ApplicationController`.

              **The Request Lifecycle**
              1. A browser sends an HTTP request (e.g., `GET /posts/1`).
              2. Rails router matches the URL to a controller action.
              3. The controller action queries the model (`Post.find(1)`).
              4. The model fetches the record from the database and returns it.
              5. The controller passes the data to the view (`show.html.erb`).
              6. The view renders HTML, which the controller sends back as the HTTP response.

              Understanding this flow is the key to understanding how any Rails application works.
            ARTICLE
          },
          {
            title: "Creating Models",
            lesson_type: "reading",
            duration_in_seconds: 660,
            article: <<~ARTICLE
              Models in Rails represent your data and encapsulate your business logic. Every model maps to a database table, and every instance of a model maps to a row in that table. This mapping is handled automatically by ActiveRecord.

              **Generating a Model**
              ```
              bin/rails generate model Article title:string body:text published:boolean
              ```
              This creates two files: a model file at `app/models/article.rb` and a migration file in `db/migrate/`. Run the migration to create the table:
              ```
              bin/rails db:migrate
              ```

              **Validations**
              Validations ensure that only valid data is saved to the database:
              ```ruby
              class Article < ApplicationRecord
                validates :title, presence: true, length: { minimum: 5 }
                validates :body, presence: true
              end
              ```

              **Associations**
              ActiveRecord associations let you declare relationships between models:
              ```ruby
              class Author < ApplicationRecord
                has_many :articles, dependent: :destroy
              end

              class Article < ApplicationRecord
                belongs_to :author
              end
              ```
              With these declarations, Rails automatically provides methods like `author.articles`, `author.articles.create(...)`, and `article.author`.

              **Scopes**
              Scopes allow you to define reusable query fragments:
              ```ruby
              scope :published, -> { where(published: true) }
              scope :recent, -> { order(created_at: :desc).limit(10) }
              ```
              You can then call `Article.published.recent` to chain queries in a readable way.

              Models are the most important layer of your application. Keeping them focused on data rules and business logic (rather than leaking that logic into controllers or views) is the hallmark of a well-designed Rails application.
            ARTICLE
          },
          {
            title: "Building Controllers",
            lesson_type: "reading",
            duration_in_seconds: 600,
            article: <<~ARTICLE
              Controllers are the traffic directors of your Rails application. They receive incoming HTTP requests, coordinate with models to fetch or mutate data, and instruct views to render responses.

              **Generating a Controller**
              ```
              bin/rails generate controller Articles index show new create edit update destroy
              ```

              **A Typical RESTful Controller**
              Rails encourages RESTful design. The seven standard actions map to CRUD operations:

              | Action   | HTTP Verb | Path            | Purpose                  |
              |----------|-----------|-----------------|--------------------------|
              | index    | GET       | /articles       | List all articles        |
              | show     | GET       | /articles/:id   | Show one article         |
              | new      | GET       | /articles/new   | Form to create           |
              | create   | POST      | /articles       | Save a new article       |
              | edit     | GET       | /articles/:id/edit | Form to edit          |
              | update   | PATCH/PUT | /articles/:id   | Save changes             |
              | destroy  | DELETE    | /articles/:id   | Delete an article        |

              **Strong Parameters**
              Controllers should never pass raw user input directly to models. Use strong parameters to whitelist allowed attributes:
              ```ruby
              def article_params
                params.require(:article).permit(:title, :body, :published)
              end
              ```

              **Before Actions**
              Use `before_action` to extract repeated logic:
              ```ruby
              before_action :set_article, only: [:show, :edit, :update, :destroy]

              private

              def set_article
                @article = Article.find(params[:id])
              end
              ```

              **Responding to Different Formats**
              Controllers can respond to HTML, JSON, XML, and more using `respond_to`:
              ```ruby
              def show
                respond_to do |format|
                  format.html
                  format.json { render json: @article }
                end
              end
              ```

              Keeping controllers thin — delegating business logic to models and presentation to views — is a widely accepted best practice in Rails development.
            ARTICLE
          }
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
          {
            title: "What is React?",
            lesson_type: "reading",
            duration_in_seconds: 480,
            article: <<~ARTICLE
              React is an open-source JavaScript library for building user interfaces, developed and maintained by Meta (formerly Facebook). First released in 2013, it has become the most widely adopted frontend library in the industry, powering applications at Facebook, Instagram, Netflix, Airbnb, and thousands of other companies.

              **The Core Idea: Components**
              React's fundamental building block is the component. A component is a self-contained, reusable piece of UI that manages its own structure, style, and behaviour. You compose complex UIs by nesting smaller components together, just like building with LEGO bricks.

              ```jsx
              function WelcomeBanner({ username }) {
                return <h1>Welcome back, {username}!</h1>;
              }
              ```

              **The Virtual DOM**
              One of React's key innovations is the Virtual DOM. Instead of directly manipulating the browser's real DOM on every state change (which is slow), React maintains a lightweight in-memory copy. When state changes, React computes the difference (diff) between the old and new Virtual DOM and applies only the minimal set of changes to the real DOM. This makes React applications fast even with complex, frequently updating UIs.

              **Declarative vs. Imperative**
              Traditional DOM manipulation is imperative: you tell the browser exactly what to do step by step. React is declarative: you describe what the UI should look like for a given state, and React figures out how to get there. This makes your code easier to reason about and debug.

              **One-Way Data Flow**
              Data in React flows in one direction — from parent components to child components via props. This predictable flow makes it straightforward to trace where data comes from and how it changes.

              React itself is intentionally minimal — it only handles the View layer. For routing, state management, and server communication you pair it with libraries like React Router, Redux or Zustand, and Axios or React Query.
            ARTICLE
          },
          {
            title: "JSX Syntax",
            lesson_type: "reading",
            duration_in_seconds: 540,
            article: <<~ARTICLE
              JSX (JavaScript XML) is a syntax extension for JavaScript that lets you write HTML-like markup directly inside your JavaScript code. It is not a template language — it is syntactic sugar that gets compiled to regular JavaScript function calls by tools like Babel or the SWC compiler.

              **Basic JSX**
              ```jsx
              const element = <h1 className="title">Hello, world!</h1>;
              ```
              Under the hood, this compiles to:
              ```js
              const element = React.createElement("h1", { className: "title" }, "Hello, world!");
              ```

              **Key Differences from HTML**
              - Use `className` instead of `class` (since `class` is a reserved word in JavaScript).
              - Use `htmlFor` instead of `for` on labels.
              - All tags must be closed, including self-closing ones: `<img />`, `<br />`.
              - Event handlers use camelCase: `onClick`, `onChange`, `onSubmit`.

              **Embedding JavaScript Expressions**
              Wrap any JavaScript expression in curly braces `{}` to embed it in JSX:
              ```jsx
              const name = "Alice";
              const element = <p>Hello, {name}! Today is {new Date().toLocaleDateString()}.</p>;
              ```

              **Conditional Rendering**
              ```jsx
              function Alert({ isError, message }) {
                return (
                  <div className={isError ? "alert-error" : "alert-info"}>
                    {isError && <strong>Error: </strong>}
                    {message}
                  </div>
                );
              }
              ```

              **Rendering Lists**
              ```jsx
              const items = ["Apple", "Banana", "Cherry"];
              const list = (
                <ul>
                  {items.map((item) => (
                    <li key={item}>{item}</li>
                  ))}
                </ul>
              );
              ```
              Always provide a stable, unique `key` prop when rendering lists so React can efficiently track which items changed.

              JSX may look unusual at first, but combining markup and logic in a single file encourages building cohesive, encapsulated components rather than scattering logic across separate template files.
            ARTICLE
          }
        ]
      },
      {
        title: "Hooks and State",
        description: "Manage component state and side effects with hooks.",
        lessons: [
          {
            title: "useState Hook",
            lesson_type: "reading",
            duration_in_seconds: 600,
            article: <<~ARTICLE
              `useState` is the most fundamental React hook. It lets you add reactive state to a functional component. Before hooks were introduced in React 16.8, only class components could hold local state — `useState` brought that capability to functional components with a much simpler API.

              **Basic Usage**
              ```jsx
              import { useState } from "react";

              function Counter() {
                const [count, setCount] = useState(0);

                return (
                  <div>
                    <p>Count: {count}</p>
                    <button onClick={() => setCount(count + 1)}>Increment</button>
                    <button onClick={() => setCount(count - 1)}>Decrement</button>
                    <button onClick={() => setCount(0)}>Reset</button>
                  </div>
                );
              }
              ```

              `useState(0)` declares a state variable `count` initialised to `0` and a setter function `setCount`. When you call `setCount` with a new value, React re-renders the component with the updated state.

              **Functional Updates**
              When the new state depends on the previous state, pass a function to the setter to avoid stale closure bugs:
              ```jsx
              setCount((prev) => prev + 1);
              ```

              **State with Objects**
              State can be any JavaScript value — numbers, strings, arrays, or objects. When using objects, always spread the previous state to avoid losing other fields:
              ```jsx
              const [form, setForm] = useState({ name: "", email: "" });

              function handleNameChange(e) {
                setForm((prev) => ({ ...prev, name: e.target.value }));
              }
              ```

              **Lazy Initialisation**
              If the initial state is expensive to compute, pass a function instead of a value — React will call it only on the first render:
              ```jsx
              const [data, setData] = useState(() => expensiveComputation());
              ```

              **Rules of Hooks**
              - Only call hooks at the top level of a component or custom hook — never inside loops, conditions, or nested functions.
              - Only call hooks from React functional components or custom hooks.

              These rules ensure React can correctly track hook state across re-renders.
            ARTICLE
          },
          {
            title: "useEffect Hook",
            lesson_type: "reading",
            duration_in_seconds: 720,
            article: <<~ARTICLE
              `useEffect` lets you perform side effects in functional components. Side effects are operations that reach outside the React rendering pipeline: fetching data from an API, subscribing to a WebSocket, updating the document title, setting up a timer, or directly manipulating the DOM.

              **Basic Usage**
              ```jsx
              import { useState, useEffect } from "react";

              function UserProfile({ userId }) {
                const [user, setUser] = useState(null);

                useEffect(() => {
                  fetch(`/api/users/${userId}`)
                    .then((res) => res.json())
                    .then((data) => setUser(data));
                }, [userId]);

                if (!user) return <p>Loading...</p>;
                return <h2>{user.name}</h2>;
              }
              ```

              **The Dependency Array**
              The second argument to `useEffect` is the dependency array:
              - `[]` — run once after the initial render (equivalent to `componentDidMount`).
              - `[userId]` — run after the initial render and whenever `userId` changes.
              - Omitting the array — run after every render (use sparingly; often a sign of a design issue).

              **Cleanup**
              If your effect sets up a subscription or timer, return a cleanup function to avoid memory leaks:
              ```jsx
              useEffect(() => {
                const intervalId = setInterval(() => setTick((t) => t + 1), 1000);
                return () => clearInterval(intervalId);
              }, []);
              ```
              React calls the cleanup function before re-running the effect and when the component unmounts.

              **Common Pitfalls**
              - Including a function defined outside the effect in the deps array can cause infinite loops. Move the function inside the effect or wrap it with `useCallback`.
              - Do not use async functions directly as the effect callback. Instead, define an async function inside the effect and call it immediately:
              ```jsx
              useEffect(() => {
                async function fetchData() {
                  const res = await fetch("/api/data");
                  setData(await res.json());
                }
                fetchData();
              }, []);
              ```

              Mastering `useEffect` and its dependency array is one of the most important skills in React development.
            ARTICLE
          },
          {
            title: "Custom Hooks",
            lesson_type: "reading",
            duration_in_seconds: 660,
            article: <<~ARTICLE
              Custom hooks are one of the most powerful features in React. They let you extract stateful logic from a component and share it across multiple components — without changing the component hierarchy or introducing render props or higher-order components.

              A custom hook is simply a JavaScript function whose name starts with `use` and that calls other hooks internally.

              **Example: useLocalStorage**
              ```jsx
              import { useState, useEffect } from "react";

              function useLocalStorage(key, initialValue) {
                const [value, setValue] = useState(() => {
                  const stored = localStorage.getItem(key);
                  return stored !== null ? JSON.parse(stored) : initialValue;
                });

                useEffect(() => {
                  localStorage.setItem(key, JSON.stringify(value));
                }, [key, value]);

                return [value, setValue];
              }
              ```
              Any component can now persist state in localStorage with one line:
              ```jsx
              const [theme, setTheme] = useLocalStorage("theme", "light");
              ```

              **Example: useFetch**
              ```jsx
              function useFetch(url) {
                const [data, setData] = useState(null);
                const [loading, setLoading] = useState(true);
                const [error, setError] = useState(null);

                useEffect(() => {
                  setLoading(true);
                  fetch(url)
                    .then((res) => {
                      if (!res.ok) throw new Error(res.statusText);
                      return res.json();
                    })
                    .then(setData)
                    .catch(setError)
                    .finally(() => setLoading(false));
                }, [url]);

                return { data, loading, error };
              }
              ```
              Usage:
              ```jsx
              const { data: posts, loading, error } = useFetch("/api/posts");
              ```

              **Benefits**
              - **Separation of concerns** — keep components focused on rendering, not data-fetching logic.
              - **Reusability** — share the same hook across multiple components.
              - **Testability** — test hook logic independently from component rendering.
              - **Readability** — component code becomes cleaner and easier to understand.

              When you find yourself copying and pasting stateful logic between components, that is a strong signal to extract it into a custom hook.
            ARTICLE
          }
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
          {
            title: "Color Theory",
            lesson_type: "reading",
            duration_in_seconds: 600,
            article: <<~ARTICLE
              Color theory is the body of practical guidance for mixing colors and the visual effects of a specific color combination. For UI/UX designers, understanding color theory is essential for creating interfaces that are visually appealing, accessible, and emotionally effective.

              **The Color Wheel**
              The traditional color wheel organises colors into three groups:
              - **Primary colors**: Red, yellow, blue (in traditional theory) or Red, green, blue (RGB for screens).
              - **Secondary colors**: Formed by mixing two primary colors (e.g., red + blue = purple).
              - **Tertiary colors**: Formed by mixing a primary and an adjacent secondary color.

              **Color Relationships**
              - **Complementary**: Colors opposite on the wheel (e.g., blue and orange). High contrast, vibrant — great for call-to-action buttons but use sparingly.
              - **Analogous**: Colors adjacent on the wheel (e.g., blue, blue-green, green). Harmonious and pleasing — ideal for backgrounds and large surfaces.
              - **Triadic**: Three colors equally spaced on the wheel. Balanced and colorful — use one dominant, two as accents.
              - **Monochromatic**: Variations of a single hue (tints, shades, tones). Elegant and cohesive.

              **Color Psychology**
              Colors carry emotional associations that vary by culture but have some universal tendencies:
              - **Blue**: Trust, calm, professionalism — common in finance and tech (PayPal, Facebook, LinkedIn).
              - **Red**: Urgency, passion, energy — used for sale tags, alerts, and food brands.
              - **Green**: Nature, health, success — common in fintech and wellness apps.
              - **Yellow**: Optimism, warmth, caution — used for highlights and warnings.
              - **Purple**: Luxury, creativity, wisdom — popular in beauty and premium brands.

              **Accessibility**
              Always check color contrast ratios against WCAG guidelines. A minimum contrast ratio of 4.5:1 is required for normal text (AA standard). Use tools like the WebAIM Contrast Checker to verify your palette is accessible to users with color vision deficiencies.

              A strong color system defines a primary brand color, a secondary accent, and a set of neutral grays, plus semantic colors for success, warning, error, and info states. Keep your palette small and purposeful.
            ARTICLE
          },
          {
            title: "Typography Basics",
            lesson_type: "reading",
            duration_in_seconds: 660,
            article: <<~ARTICLE
              Typography is the art and technique of arranging type to make written language legible, readable, and visually appealing. In UI design, typography does far more than display words — it establishes hierarchy, guides attention, communicates brand personality, and directly impacts how users perceive your product.

              **Key Typography Terms**
              - **Typeface vs. Font**: A typeface is a design family (e.g., "Inter"). A font is a specific variation within that family (e.g., "Inter Bold 16px").
              - **Serif**: Typefaces with small decorative strokes at the ends of letterforms (e.g., Times New Roman, Georgia). Often feel traditional and authoritative.
              - **Sans-serif**: Typefaces without serifs (e.g., Inter, Helvetica, Roboto). Feel modern and clean — the dominant choice for digital interfaces.
              - **Monospace**: Every character occupies the same horizontal space (e.g., JetBrains Mono). Essential for code blocks.

              **Type Scale and Hierarchy**
              Establish a clear type scale with distinct sizes for headings, subheadings, body text, captions, and labels. A common ratio is 1.25 (Major Third) or 1.333 (Perfect Fourth):

              | Level    | Example Size |
              |----------|-------------|
              | H1       | 48px        |
              | H2       | 36px        |
              | H3       | 28px        |
              | H4       | 22px        |
              | Body     | 16px        |
              | Caption  | 12px        |

              **Line Length and Line Height**
              - Optimal line length for body text is 60–80 characters per line. Lines that are too long cause the eye to lose its place; lines that are too short create choppy, exhausting reading.
              - Line height (leading) should be 1.4–1.6× the font size for body text. Tighter line heights work for headings.

              **Font Pairing**
              A classic approach is to pair one display/serif typeface for headings and one sans-serif for body text. When in doubt, pair typefaces from the same family (e.g., different weights of Inter) — it is almost impossible to go wrong.

              **Accessibility**
              - Minimum body text size: 16px for most users.
              - Avoid using light font weights (100–300) for body text, especially on bright backgrounds.
              - Never use pure black (#000000) on pure white (#FFFFFF) — slightly off-black (#1a1a1a) on off-white (#f8f8f8) is easier on the eyes.

              Good typography is mostly invisible — users do not notice it, they just find the content easy to read. Bad typography, on the other hand, creates friction that erodes trust in your entire product.
            ARTICLE
          }
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
