/**
 * Firestore REST API seeder for Online Learning App
 * Project: online-learning-app-e8b52
 * Uses Firebase CLI stored access token for authentication.
 */

const https = require('https');
const fs = require('fs');
const path = require('path');

// ─── AUTH ──────────────────────────────────────────────────────────────────

const configPath = path.join(
  process.env.USERPROFILE || process.env.HOME,
  '.config', 'configstore', 'firebase-tools.json'
);
const config = JSON.parse(fs.readFileSync(configPath, 'utf8'));
const ACCESS_TOKEN = config.tokens.access_token;
const PROJECT_ID = 'online-learning-app-e8b52';
const BASE_URL = `firestore.googleapis.com`;
const DB_PATH = `/v1/projects/${PROJECT_ID}/databases/(default)/documents`;

// ─── REST HELPERS ──────────────────────────────────────────────────────────

function firestoreValue(val) {
  if (val === null || val === undefined) return { nullValue: null };
  if (typeof val === 'boolean') return { booleanValue: val };
  if (typeof val === 'number') {
    if (Number.isInteger(val)) return { integerValue: String(val) };
    return { doubleValue: val };
  }
  if (typeof val === 'string') return { stringValue: val };
  if (val && val._seconds !== undefined) return { timestampValue: new Date(val._seconds * 1000).toISOString() };
  if (Array.isArray(val)) return { arrayValue: { values: val.map(firestoreValue) } };
  if (typeof val === 'object') {
    const fields = {};
    for (const [k, v] of Object.entries(val)) {
      fields[k] = firestoreValue(v);
    }
    return { mapValue: { fields } };
  }
  return { stringValue: String(val) };
}

function toFirestoreDoc(data) {
  const fields = {};
  for (const [k, v] of Object.entries(data)) {
    fields[k] = firestoreValue(v);
  }
  return { fields };
}

function request(method, path, body) {
  return new Promise((resolve, reject) => {
    const bodyStr = body ? JSON.stringify(body) : undefined;
    const options = {
      hostname: BASE_URL,
      path: path,
      method: method,
      headers: {
        'Authorization': `Bearer ${ACCESS_TOKEN}`,
        'Content-Type': 'application/json',
      },
    };
    if (bodyStr) options.headers['Content-Length'] = Buffer.byteLength(bodyStr);

    const req = https.request(options, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        if (res.statusCode >= 200 && res.statusCode < 300) {
          resolve(JSON.parse(data || '{}'));
        } else {
          reject(new Error(`HTTP ${res.statusCode} at ${path}: ${data.slice(0, 300)}`));
        }
      });
    });
    req.on('error', reject);
    if (bodyStr) req.write(bodyStr);
    req.end();
  });
}

async function setDoc(collectionPath, docId, data) {
  const p = `${DB_PATH}/${collectionPath}/${docId}`;
  return request('PATCH', `${p}?updateMask.fieldPaths=${Object.keys(data).join('&updateMask.fieldPaths=')}`, toFirestoreDoc(data));
}

async function getCollection(collectionPath) {
  try {
    const result = await request('GET', `${DB_PATH}/${collectionPath}`);
    return result.documents || [];
  } catch (e) {
    return [];
  }
}

function sleep(ms) { return new Promise(r => setTimeout(r, ms)); }

const NOW_ISO = new Date().toISOString();
const NOW = { _seconds: Math.floor(Date.now() / 1000), _nanoseconds: 0 };

// ─── COURSE DATA ────────────────────────────────────────────────────────────

const COURSES = [
  {
    id: 'course_flutter_mastery',
    data: {
      title: 'Flutter & Dart – The Complete App Development Bootcamp',
      titleLower: 'flutter & dart – the complete app development bootcamp',
      description: 'Master Flutter from zero to hero. Build beautiful, natively compiled apps for mobile, web, and desktop from a single codebase. Covers Dart fundamentals, widgets, state management, Firebase integration, and publishing to app stores.',
      category: 'Mobile Development',
      level: 'Beginner',
      language: 'English',
      thumbnailURL: 'https://images.unsplash.com/photo-1512941937669-90a1b58e7e9c?w=800&q=80',
      instructor: 'Angela Yu',
      mentorId: '',
      price: 1499,
      rating: 4.8,
      averageRating: 4.8,
      reviewCount: 3842,
      enrollmentCount: 12500,
      enrolledCount: 12500,
      totalLessons: 8,
      durationHours: 42,
      status: 'published',
      isPublished: true,
      isFeatured: true,
      isApproved: true,
      videoUrl: 'https://www.youtube.com/watch?v=VPvVD8t02U8',
      createdAt: NOW_ISO,
      updatedAt: NOW_ISO,
    },
    lessons: [
      { title: 'Introduction to Flutter & Dart', contentUrl: 'https://www.youtube.com/watch?v=VPvVD8t02U8', order: 1, duration: 12 },
      { title: 'Setting Up Your Development Environment', contentUrl: 'https://www.youtube.com/watch?v=x0uinJvhNxI', order: 2, duration: 15 },
      { title: 'Dart Basics: Variables, Types & Functions', contentUrl: 'https://www.youtube.com/watch?v=Ej_Pcr4uC2Q', order: 3, duration: 20 },
      { title: 'Your First Flutter Widget', contentUrl: 'https://www.youtube.com/watch?v=1ukSR1GRtMU', order: 4, duration: 18 },
      { title: 'Layouts: Row, Column & Stack', contentUrl: 'https://www.youtube.com/watch?v=RJEnTRgKiKs', order: 5, duration: 22 },
      { title: 'Stateful vs Stateless Widgets', contentUrl: 'https://www.youtube.com/watch?v=AqCMFXEmf3w', order: 6, duration: 16 },
      { title: 'Navigation & Routing in Flutter', contentUrl: 'https://www.youtube.com/watch?v=nyvwx7o277U', order: 7, duration: 19 },
      { title: 'Firebase Auth Integration', contentUrl: 'https://www.youtube.com/watch?v=rWamixHIKmQ', order: 8, duration: 25 },
    ],
    quiz: {
      title: 'Flutter & Dart Fundamentals Quiz',
      description: 'Test your knowledge of Flutter widgets, Dart basics, and app architecture.',
      passingScore: 70, maxAttempts: 3, timeLimit: 20,
      questions: [
        { text: 'Which is the correct way to declare a final variable in Dart?', order: 1, explanation: 'In Dart, "final" is for variables set once; "const" is for compile-time constants.',
          options: [{ text: 'final String name = "Flutter";', isCorrect: true }, { text: 'let name = "Flutter";', isCorrect: false }, { text: 'var final name = "Flutter";', isCorrect: false }, { text: 'string name = "Flutter";', isCorrect: false }] },
        { text: 'What is a StatelessWidget in Flutter?', order: 2, explanation: 'A StatelessWidget cannot change its state during the widget lifetime.',
          options: [{ text: 'A widget with mutable state', isCorrect: false }, { text: 'A widget that cannot change its state once built', isCorrect: true }, { text: 'A widget with no children', isCorrect: false }, { text: 'A widget that only displays text', isCorrect: false }] },
        { text: 'Which widget lays out children horizontally?', order: 3, explanation: 'Row arranges children horizontally; Column arranges them vertically.',
          options: [{ text: 'Column', isCorrect: false }, { text: 'Stack', isCorrect: false }, { text: 'Row', isCorrect: true }, { text: 'Flex', isCorrect: false }] },
        { text: 'What does setState() do in Flutter?', order: 4, explanation: 'setState() notifies the framework that the internal state changed and triggers rebuild.',
          options: [{ text: 'Saves data to Firestore', isCorrect: false }, { text: 'Notifies the framework to rebuild the widget', isCorrect: true }, { text: 'Navigates to a new screen', isCorrect: false }, { text: 'Closes the current widget', isCorrect: false }] },
        { text: 'Which package is most popular for state management in Flutter?', order: 5, explanation: 'Provider is recommended by the Flutter team for state management.',
          options: [{ text: 'axios', isCorrect: false }, { text: 'redux-flutter', isCorrect: false }, { text: 'provider', isCorrect: true }, { text: 'mobx-dart', isCorrect: false }] },
      ],
    },
  },
  {
    id: 'course_web_dev_bootcamp',
    data: {
      title: 'The Complete Web Development Bootcamp 2024',
      titleLower: 'the complete web development bootcamp 2024',
      description: 'Become a full-stack web developer with HTML, CSS, JavaScript, React, Node.js, and MongoDB. Build 16+ real projects including a Netflix clone and e-commerce site.',
      category: 'Web Development',
      level: 'Beginner',
      language: 'English',
      thumbnailURL: 'https://images.unsplash.com/photo-1547658719-da2b51169166?w=800&q=80',
      instructor: 'Dr. Angela Yu',
      mentorId: '',
      price: 1299,
      rating: 4.7,
      averageRating: 4.7,
      reviewCount: 5621,
      enrollmentCount: 22000,
      enrolledCount: 22000,
      totalLessons: 8,
      durationHours: 55,
      status: 'published',
      isPublished: true,
      isFeatured: true,
      isApproved: true,
      videoUrl: 'https://www.youtube.com/watch?v=pQN-pnXPaVg',
      createdAt: NOW_ISO,
      updatedAt: NOW_ISO,
    },
    lessons: [
      { title: 'HTML Fundamentals', contentUrl: 'https://www.youtube.com/watch?v=pQN-pnXPaVg', order: 1, duration: 18 },
      { title: 'CSS Styling & Selectors', contentUrl: 'https://www.youtube.com/watch?v=1Rs2ND1ryYc', order: 2, duration: 22 },
      { title: 'CSS Flexbox & Grid', contentUrl: 'https://www.youtube.com/watch?v=JJSoEo8JSnc', order: 3, duration: 20 },
      { title: 'JavaScript Variables & Data Types', contentUrl: 'https://www.youtube.com/watch?v=W6NZfCO5SIk', order: 4, duration: 24 },
      { title: 'DOM Manipulation', contentUrl: 'https://www.youtube.com/watch?v=y17RuWkWdn8', order: 5, duration: 26 },
      { title: 'Introduction to React.js', contentUrl: 'https://www.youtube.com/watch?v=Ke90Tje7VS0', order: 6, duration: 30 },
      { title: 'React Hooks – useState & useEffect', contentUrl: 'https://www.youtube.com/watch?v=O6P86uwfdR0', order: 7, duration: 25 },
      { title: 'Node.js & Express Basics', contentUrl: 'https://www.youtube.com/watch?v=fBNz5xF-Kx4', order: 8, duration: 28 },
    ],
    quiz: {
      title: 'Web Development Fundamentals Quiz',
      description: 'Test your HTML, CSS, and JavaScript knowledge.',
      passingScore: 70, maxAttempts: 3, timeLimit: 15,
      questions: [
        { text: 'Which HTML tag creates a hyperlink?', order: 1, explanation: 'The <a> anchor tag creates hyperlinks.',
          options: [{ text: '<link>', isCorrect: false }, { text: '<a>', isCorrect: true }, { text: '<href>', isCorrect: false }, { text: '<url>', isCorrect: false }] },
        { text: 'What does CSS stand for?', order: 2, explanation: 'CSS = Cascading Style Sheets.',
          options: [{ text: 'Computer Style Sheets', isCorrect: false }, { text: 'Cascading Style Sheets', isCorrect: true }, { text: 'Creative Style Syntax', isCorrect: false }, { text: 'Coded Style Sheets', isCorrect: false }] },
        { text: 'Which JS method selects an element by ID?', order: 3, explanation: 'document.getElementById() selects by the ID attribute.',
          options: [{ text: 'document.getElement()', isCorrect: false }, { text: 'document.querySelector()', isCorrect: false }, { text: 'document.getElementById()', isCorrect: true }, { text: 'document.findById()', isCorrect: false }] },
        { text: 'In CSS Flexbox, which property aligns items along the main axis?', order: 4, explanation: 'justify-content aligns flex items along the main (horizontal) axis.',
          options: [{ text: 'align-items', isCorrect: false }, { text: 'justify-content', isCorrect: true }, { text: 'flex-direction', isCorrect: false }, { text: 'flex-wrap', isCorrect: false }] },
        { text: 'What is an arrow function in JavaScript?', order: 5, explanation: 'Arrow functions use the => syntax from ES6+.',
          options: [{ text: 'function myFn() => {}', isCorrect: false }, { text: 'const myFn = () => {}', isCorrect: true }, { text: 'arrow myFn() {}', isCorrect: false }, { text: 'let myFn => () {}', isCorrect: false }] },
      ],
    },
  },
  {
    id: 'course_python_data_science',
    data: {
      title: 'Python for Data Science & Machine Learning Bootcamp',
      titleLower: 'python for data science & machine learning bootcamp',
      description: 'Learn Python, NumPy, Pandas, Matplotlib, Scikit-Learn, and TensorFlow. Work on real datasets and build ML models for classification, regression, clustering, and deep learning.',
      category: 'Data Science',
      level: 'Intermediate',
      language: 'English',
      thumbnailURL: 'https://images.unsplash.com/photo-1551288049-bebda4e38f71?w=800&q=80',
      instructor: 'Jose Portilla',
      mentorId: '',
      price: 1799,
      rating: 4.6,
      averageRating: 4.6,
      reviewCount: 4100,
      enrollmentCount: 15800,
      enrolledCount: 15800,
      totalLessons: 6,
      durationHours: 38,
      status: 'published',
      isPublished: true,
      isFeatured: true,
      isApproved: true,
      videoUrl: 'https://www.youtube.com/watch?v=LHBE6Q9XlzI',
      createdAt: NOW_ISO,
      updatedAt: NOW_ISO,
    },
    lessons: [
      { title: 'Python Crash Course', contentUrl: 'https://www.youtube.com/watch?v=LHBE6Q9XlzI', order: 1, duration: 25 },
      { title: 'NumPy Arrays & Operations', contentUrl: 'https://www.youtube.com/watch?v=QUT1VHiLmmI', order: 2, duration: 20 },
      { title: 'Pandas DataFrames', contentUrl: 'https://www.youtube.com/watch?v=vmEHCJofslg', order: 3, duration: 22 },
      { title: 'Matplotlib & Seaborn Visualization', contentUrl: 'https://www.youtube.com/watch?v=a9UrKTVEeZA', order: 4, duration: 18 },
      { title: 'Linear Regression with Scikit-Learn', contentUrl: 'https://www.youtube.com/watch?v=7ArmBVF2dCs', order: 5, duration: 28 },
      { title: 'Classification Algorithms', contentUrl: 'https://www.youtube.com/watch?v=pqNCD_5r0IU', order: 6, duration: 24 },
    ],
    quiz: {
      title: 'Python & Data Science Quiz',
      description: 'Test your Python programming and data science concepts.',
      passingScore: 65, maxAttempts: 3, timeLimit: 20,
      questions: [
        { text: 'Which Python library is primarily used for numerical computations?', order: 1, explanation: 'NumPy is the fundamental package for numerical computing.',
          options: [{ text: 'Pandas', isCorrect: false }, { text: 'Matplotlib', isCorrect: false }, { text: 'NumPy', isCorrect: true }, { text: 'Scikit-Learn', isCorrect: false }] },
        { text: 'What does a Pandas DataFrame represent?', order: 2, explanation: 'A DataFrame is a 2D labeled table with rows and columns.',
          options: [{ text: 'A single column of data', isCorrect: false }, { text: 'A 2D labeled table with rows and columns', isCorrect: true }, { text: 'A Python dictionary', isCorrect: false }, { text: 'A neural network layer', isCorrect: false }] },
        { text: 'What is overfitting in machine learning?', order: 3, explanation: 'Overfitting is when a model learns the training data too well, reducing generalization.',
          options: [{ text: 'When the model is too simple', isCorrect: false }, { text: 'When the model performs well on training data but poorly on new data', isCorrect: true }, { text: 'When there is too much training data', isCorrect: false }, { text: 'When the learning rate is too low', isCorrect: false }] },
        { text: 'Which algorithm clusters unlabeled data?', order: 4, explanation: 'K-Means is an unsupervised algorithm that groups data into K clusters.',
          options: [{ text: 'Logistic Regression', isCorrect: false }, { text: 'Decision Tree', isCorrect: false }, { text: 'K-Means Clustering', isCorrect: true }, { text: 'Linear Regression', isCorrect: false }] },
        { text: 'What does the pandas read_csv() function do?', order: 5, explanation: 'read_csv() reads a CSV file and returns it as a DataFrame.',
          options: [{ text: 'Writes data to a CSV file', isCorrect: false }, { text: 'Reads a CSV file into a DataFrame', isCorrect: true }, { text: 'Converts a list to a CSV', isCorrect: false }, { text: 'Deletes a CSV file', isCorrect: false }] },
      ],
    },
  },
  {
    id: 'course_ui_ux_design',
    data: {
      title: 'UI/UX Design Masterclass – Figma to Production',
      titleLower: 'ui/ux design masterclass – figma to production',
      description: 'Learn UX research, wireframing, prototyping, and visual design using Figma. Create stunning mobile and web interfaces and build a professional design portfolio.',
      category: 'Design',
      level: 'Beginner',
      language: 'English',
      thumbnailURL: 'https://images.unsplash.com/photo-1561070791-2526d30994b5?w=800&q=80',
      instructor: 'Michal Malewicz',
      mentorId: '',
      price: 999,
      rating: 4.9,
      averageRating: 4.9,
      reviewCount: 2890,
      enrollmentCount: 9200,
      enrolledCount: 9200,
      totalLessons: 6,
      durationHours: 30,
      status: 'published',
      isPublished: true,
      isFeatured: false,
      isApproved: true,
      videoUrl: 'https://www.youtube.com/watch?v=wIuVvCuiSkQ',
      createdAt: NOW_ISO,
      updatedAt: NOW_ISO,
    },
    lessons: [
      { title: 'Design Thinking Process', contentUrl: 'https://www.youtube.com/watch?v=wIuVvCuiSkQ', order: 1, duration: 14 },
      { title: 'Introduction to Figma', contentUrl: 'https://www.youtube.com/watch?v=FTFaQWZBqQ8', order: 2, duration: 20 },
      { title: 'Typography in UI Design', contentUrl: 'https://www.youtube.com/watch?v=QrNi9FmdlxY', order: 3, duration: 16 },
      { title: 'Color Theory for Designers', contentUrl: 'https://www.youtube.com/watch?v=_2LLXnUdUIc', order: 4, duration: 18 },
      { title: 'Building a Design System', contentUrl: 'https://www.youtube.com/watch?v=EK-pHkc5EL4', order: 5, duration: 22 },
      { title: 'Mobile App Prototyping', contentUrl: 'https://www.youtube.com/watch?v=lTIeZ2ahEkQ', order: 6, duration: 25 },
    ],
    quiz: {
      title: 'UI/UX Design Principles Quiz',
      description: 'Test your design thinking and Figma skills.',
      passingScore: 70, maxAttempts: 3, timeLimit: 15,
      questions: [
        { text: 'What does UX stand for?', order: 1, explanation: 'UX = User Experience.',
          options: [{ text: 'Unique Exchange', isCorrect: false }, { text: 'User Experience', isCorrect: true }, { text: 'Universal Extension', isCorrect: false }, { text: 'User Excellence', isCorrect: false }] },
        { text: 'What is a wireframe in UI/UX?', order: 2, explanation: 'Wireframes are low-fidelity layouts showing structure without visual design details.',
          options: [{ text: 'A high-fidelity mockup with colors', isCorrect: false }, { text: 'A low-fidelity skeletal layout of a UI', isCorrect: true }, { text: 'The final code of a web page', isCorrect: false }, { text: 'A user interview recording', isCorrect: false }] },
        { text: 'What is a design system?', order: 3, explanation: 'A design system is a collection of reusable components and guidelines for consistent UI.',
          options: [{ text: 'A single page template', isCorrect: false }, { text: 'A set of reusable components and design guidelines', isCorrect: true }, { text: 'A mood board for inspiration', isCorrect: false }, { text: 'A brand logo collection', isCorrect: false }] },
        { text: 'Which color property determines lightness/darkness?', order: 4, explanation: 'Value (or lightness) determines how light or dark a color appears.',
          options: [{ text: 'Hue', isCorrect: false }, { text: 'Saturation', isCorrect: false }, { text: 'Value (Lightness)', isCorrect: true }, { text: 'Temperature', isCorrect: false }] },
        { text: 'What is the primary purpose of user testing?', order: 5, explanation: 'User testing validates design decisions by observing real users interacting with your product.',
          options: [{ text: 'To make the design prettier', isCorrect: false }, { text: 'To validate design decisions with real users', isCorrect: true }, { text: 'To check browser compatibility', isCorrect: false }, { text: 'To write code faster', isCorrect: false }] },
      ],
    },
  },
  {
    id: 'course_devops_kubernetes',
    data: {
      title: 'DevOps Bootcamp – Docker, Kubernetes & CI/CD',
      titleLower: 'devops bootcamp – docker, kubernetes & ci/cd',
      description: 'Master DevOps practices. Learn Docker, Kubernetes, Jenkins, GitHub Actions, and Terraform. Deploy scalable microservices and set up automated CI/CD pipelines.',
      category: 'DevOps',
      level: 'Advanced',
      language: 'English',
      thumbnailURL: 'https://images.unsplash.com/photo-1667372393119-3d4c48d07fc9?w=800&q=80',
      instructor: 'Nana Janashia',
      mentorId: '',
      price: 1999,
      rating: 4.8,
      averageRating: 4.8,
      reviewCount: 1850,
      enrollmentCount: 6200,
      enrolledCount: 6200,
      totalLessons: 6,
      durationHours: 48,
      status: 'published',
      isPublished: true,
      isFeatured: true,
      isApproved: true,
      videoUrl: 'https://www.youtube.com/watch?v=3c-iBn73dDE',
      createdAt: NOW_ISO,
      updatedAt: NOW_ISO,
    },
    lessons: [
      { title: 'DevOps Introduction & Linux Basics', contentUrl: 'https://www.youtube.com/watch?v=3c-iBn73dDE', order: 1, duration: 30 },
      { title: 'Docker Fundamentals', contentUrl: 'https://www.youtube.com/watch?v=pTFZFxd5T2s', order: 2, duration: 25 },
      { title: 'Docker Compose & Multi-Container Apps', contentUrl: 'https://www.youtube.com/watch?v=HG6yIjZapSA', order: 3, duration: 22 },
      { title: 'Kubernetes Architecture & Pods', contentUrl: 'https://www.youtube.com/watch?v=X48VuDVv0do', order: 4, duration: 35 },
      { title: 'Kubernetes Deployments & Services', contentUrl: 'https://www.youtube.com/watch?v=X48VuDVv0do', order: 5, duration: 28 },
      { title: 'CI/CD Pipeline with GitHub Actions', contentUrl: 'https://www.youtube.com/watch?v=R8_veQiYBjI', order: 6, duration: 20 },
    ],
    quiz: {
      title: 'DevOps & Kubernetes Quiz',
      description: 'Test your Docker, Kubernetes, and CI/CD knowledge.',
      passingScore: 70, maxAttempts: 3, timeLimit: 20,
      questions: [
        { text: 'What is a Docker container?', order: 1, explanation: 'A Docker container is a lightweight, portable unit packaging an app and its dependencies.',
          options: [{ text: 'A virtual machine', isCorrect: false }, { text: 'A lightweight package containing an app and its dependencies', isCorrect: true }, { text: 'A cloud storage service', isCorrect: false }, { text: 'A programming language', isCorrect: false }] },
        { text: 'What command builds a Docker image?', order: 2, explanation: '"docker build" reads a Dockerfile and creates an image.',
          options: [{ text: 'docker run', isCorrect: false }, { text: 'docker create', isCorrect: false }, { text: 'docker build', isCorrect: true }, { text: 'docker start', isCorrect: false }] },
        { text: 'In Kubernetes, what is a Pod?', order: 3, explanation: 'A Pod is the smallest deployable unit in Kubernetes, containing one or more containers.',
          options: [{ text: 'A physical server', isCorrect: false }, { text: 'The smallest deployable unit with one or more containers', isCorrect: true }, { text: 'A networking rule', isCorrect: false }, { text: 'A storage volume', isCorrect: false }] },
        { text: 'What does CI/CD stand for?', order: 4, explanation: 'CI/CD = Continuous Integration / Continuous Delivery.',
          options: [{ text: 'Code Integration / Code Deployment', isCorrect: false }, { text: 'Continuous Integration / Continuous Delivery', isCorrect: true }, { text: 'Container Isolation / Container Delivery', isCorrect: false }, { text: 'Cloud Infrastructure / Cloud Delivery', isCorrect: false }] },
        { text: 'Which Kubernetes object ensures a specified number of replicas?', order: 5, explanation: 'A Deployment manages ReplicaSets to ensure the desired pod count is always running.',
          options: [{ text: 'Service', isCorrect: false }, { text: 'ConfigMap', isCorrect: false }, { text: 'Deployment', isCorrect: true }, { text: 'Namespace', isCorrect: false }] },
      ],
    },
  },
  {
    id: 'course_java_springboot',
    data: {
      title: 'Java Spring Boot – Build REST APIs & Microservices',
      titleLower: 'java spring boot – build rest apis & microservices',
      description: 'Learn Java Spring Boot to build production-ready REST APIs and microservices. Covers Spring Security, JPA/Hibernate, PostgreSQL, Docker, and testing with JUnit.',
      category: 'Backend Development',
      level: 'Intermediate',
      language: 'English',
      thumbnailURL: 'https://images.unsplash.com/photo-1544256718-3bcf237f3974?w=800&q=80',
      instructor: 'Amigoscode',
      mentorId: '',
      price: 1399,
      rating: 4.6,
      averageRating: 4.6,
      reviewCount: 2450,
      enrollmentCount: 8700,
      enrolledCount: 8700,
      totalLessons: 6,
      durationHours: 35,
      status: 'published',
      isPublished: true,
      isFeatured: false,
      isApproved: true,
      videoUrl: 'https://www.youtube.com/watch?v=9SGDpanrc8U',
      createdAt: NOW_ISO,
      updatedAt: NOW_ISO,
    },
    lessons: [
      { title: 'Spring Boot Introduction & Project Setup', contentUrl: 'https://www.youtube.com/watch?v=9SGDpanrc8U', order: 1, duration: 22 },
      { title: 'Building Your First REST API', contentUrl: 'https://www.youtube.com/watch?v=vtPkZShrvXQ', order: 2, duration: 26 },
      { title: 'Spring Data JPA & Repository Pattern', contentUrl: 'https://www.youtube.com/watch?v=8SGI_XS5OPw', order: 3, duration: 24 },
      { title: 'Spring Security & JWT Authentication', contentUrl: 'https://www.youtube.com/watch?v=b9O9NI-RJ3o', order: 4, duration: 30 },
      { title: 'Exception Handling & Validation', contentUrl: 'https://www.youtube.com/watch?v=PqpC2oBmqRw', order: 5, duration: 18 },
      { title: 'Unit Testing with JUnit 5', contentUrl: 'https://www.youtube.com/watch?v=rPbjI3UHNgE', order: 6, duration: 25 },
    ],
    quiz: {
      title: 'Java Spring Boot Quiz',
      description: 'Test your Java Spring Boot knowledge.',
      passingScore: 70, maxAttempts: 3, timeLimit: 20,
      questions: [
        { text: 'What annotation marks a Spring Boot REST controller?', order: 1, explanation: '@RestController combines @Controller and @ResponseBody to handle HTTP requests.',
          options: [{ text: '@Service', isCorrect: false }, { text: '@Component', isCorrect: false }, { text: '@RestController', isCorrect: true }, { text: '@Repository', isCorrect: false }] },
        { text: 'What does JPA stand for?', order: 2, explanation: 'JPA = Java Persistence API, for managing relational data in Java.',
          options: [{ text: 'Java Programming Application', isCorrect: false }, { text: 'Java Persistence API', isCorrect: true }, { text: 'Java Package Architecture', isCorrect: false }, { text: 'Java Process Automation', isCorrect: false }] },
        { text: 'Which HTTP method updates an existing resource?', order: 3, explanation: 'PUT is used for full updates; PATCH for partial updates.',
          options: [{ text: 'GET', isCorrect: false }, { text: 'POST', isCorrect: false }, { text: 'PUT', isCorrect: true }, { text: 'DELETE', isCorrect: false }] },
        { text: 'What is the purpose of @Autowired?', order: 4, explanation: '@Autowired enables automatic dependency injection in Spring.',
          options: [{ text: 'To define a new bean', isCorrect: false }, { text: 'To automatically inject dependencies', isCorrect: true }, { text: 'To map HTTP requests', isCorrect: false }, { text: 'To enable transactions', isCorrect: false }] },
        { text: 'Which status code indicates successful resource creation?', order: 5, explanation: 'HTTP 201 Created means a new resource was created successfully.',
          options: [{ text: '200 OK', isCorrect: false }, { text: '204 No Content', isCorrect: false }, { text: '201 Created', isCorrect: true }, { text: '302 Found', isCorrect: false }] },
      ],
    },
  },
  {
    id: 'course_react_native',
    data: {
      title: 'React Native – Build Mobile Apps with React',
      titleLower: 'react native – build mobile apps with react',
      description: 'Build cross-platform iOS and Android apps using React Native and Expo. Learn navigation, state management with Redux, REST APIs, push notifications, and app store publishing.',
      category: 'Mobile Development',
      level: 'Intermediate',
      language: 'English',
      thumbnailURL: 'https://images.unsplash.com/photo-1555774698-0b77e0d5fac6?w=800&q=80',
      instructor: 'Maximilian Schwarzmüller',
      mentorId: '',
      price: 1199,
      rating: 4.7,
      averageRating: 4.7,
      reviewCount: 3200,
      enrollmentCount: 11000,
      enrolledCount: 11000,
      totalLessons: 6,
      durationHours: 36,
      status: 'published',
      isPublished: true,
      isFeatured: false,
      isApproved: true,
      videoUrl: 'https://www.youtube.com/watch?v=0-S5a0eXPoc',
      createdAt: NOW_ISO,
      updatedAt: NOW_ISO,
    },
    lessons: [
      { title: 'React Native Introduction & Setup', contentUrl: 'https://www.youtube.com/watch?v=0-S5a0eXPoc', order: 1, duration: 20 },
      { title: 'Core Components: View, Text, Image', contentUrl: 'https://www.youtube.com/watch?v=Hf4MJH0jDb4', order: 2, duration: 22 },
      { title: 'StyleSheet & Flexbox in React Native', contentUrl: 'https://www.youtube.com/watch?v=R2eqAgR_KlU', order: 3, duration: 18 },
      { title: 'Stack Navigation with React Navigation', contentUrl: 'https://www.youtube.com/watch?v=28Xr22XDcDg', order: 4, duration: 25 },
      { title: 'Tab & Drawer Navigation', contentUrl: 'https://www.youtube.com/watch?v=nQVCkqvU1uE', order: 5, duration: 20 },
      { title: 'Fetching Data with REST APIs', contentUrl: 'https://www.youtube.com/watch?v=T3Px88x_PsA', order: 6, duration: 24 },
    ],
    quiz: {
      title: 'React Native Quiz',
      description: 'Test your React Native knowledge.',
      passingScore: 70, maxAttempts: 3, timeLimit: 15,
      questions: [
        { text: 'Which company developed React Native?', order: 1, explanation: 'React Native was developed by Meta (Facebook) and released in 2015.',
          options: [{ text: 'Google', isCorrect: false }, { text: 'Microsoft', isCorrect: false }, { text: 'Meta (Facebook)', isCorrect: true }, { text: 'Apple', isCorrect: false }] },
        { text: 'Which component is equivalent to a <div> in React Native?', order: 2, explanation: 'View is the fundamental building block in React Native, similar to <div> in HTML.',
          options: [{ text: 'Container', isCorrect: false }, { text: 'View', isCorrect: true }, { text: 'Section', isCorrect: false }, { text: 'Box', isCorrect: false }] },
        { text: 'What is Expo in React Native development?', order: 3, explanation: 'Expo is a framework that simplifies React Native development with built-in APIs.',
          options: [{ text: 'A state management library', isCorrect: false }, { text: 'A framework that simplifies React Native development', isCorrect: true }, { text: 'A design tool', isCorrect: false }, { text: 'A testing framework', isCorrect: false }] },
        { text: 'Which hook manages side effects in React Native?', order: 4, explanation: 'useEffect handles side effects like API calls, subscriptions, and timers.',
          options: [{ text: 'useState', isCorrect: false }, { text: 'useContext', isCorrect: false }, { text: 'useEffect', isCorrect: true }, { text: 'useRef', isCorrect: false }] },
        { text: 'How is styling done in React Native?', order: 5, explanation: 'React Native uses JavaScript StyleSheet objects — not CSS files.',
          options: [{ text: 'Using CSS files', isCorrect: false }, { text: 'Using JavaScript StyleSheet objects', isCorrect: true }, { text: 'Using SASS', isCorrect: false }, { text: 'Using XML attributes', isCorrect: false }] },
      ],
    },
  },
  {
    id: 'course_digital_marketing',
    data: {
      title: 'Digital Marketing Masterclass – SEO, Ads & Social Media',
      titleLower: 'digital marketing masterclass – seo, ads & social media',
      description: 'Master digital marketing from scratch. Learn SEO, Google Ads, Facebook/Instagram Ads, email marketing, content strategy, and analytics to drive real business results.',
      category: 'Marketing',
      level: 'Beginner',
      language: 'English',
      thumbnailURL: 'https://images.unsplash.com/photo-1432888622747-4eb9a8efeb07?w=800&q=80',
      instructor: 'Daragh Walsh',
      mentorId: '',
      price: 899,
      rating: 4.5,
      averageRating: 4.5,
      reviewCount: 2100,
      enrollmentCount: 7500,
      enrolledCount: 7500,
      totalLessons: 6,
      durationHours: 28,
      status: 'published',
      isPublished: true,
      isFeatured: false,
      isApproved: true,
      videoUrl: 'https://www.youtube.com/watch?v=bixR-KIJKYM',
      createdAt: NOW_ISO,
      updatedAt: NOW_ISO,
    },
    lessons: [
      { title: 'Digital Marketing Overview', contentUrl: 'https://www.youtube.com/watch?v=bixR-KIJKYM', order: 1, duration: 16 },
      { title: 'SEO On-Page Fundamentals', contentUrl: 'https://www.youtube.com/watch?v=DvwS7cV9GmQ', order: 2, duration: 20 },
      { title: 'Keyword Research Strategies', contentUrl: 'https://www.youtube.com/watch?v=OMJQPqG2Uas', order: 3, duration: 18 },
      { title: 'Google Ads Campaign Setup', contentUrl: 'https://www.youtube.com/watch?v=lD2bETVBZaM', order: 4, duration: 22 },
      { title: 'Facebook & Instagram Ads', contentUrl: 'https://www.youtube.com/watch?v=Zh7Gd37A_o0', order: 5, duration: 24 },
      { title: 'Email Marketing Essentials', contentUrl: 'https://www.youtube.com/watch?v=oeAhRNnE-es', order: 6, duration: 19 },
    ],
    quiz: {
      title: 'Digital Marketing Quiz',
      description: 'Test your SEO, ads, and digital marketing knowledge.',
      passingScore: 65, maxAttempts: 3, timeLimit: 15,
      questions: [
        { text: 'What does SEO stand for?', order: 1, explanation: 'SEO = Search Engine Optimization.',
          options: [{ text: 'Social Engagement Optimization', isCorrect: false }, { text: 'Search Engine Optimization', isCorrect: true }, { text: 'Site Enhancement Operations', isCorrect: false }, { text: 'Search Experience Optimization', isCorrect: false }] },
        { text: 'What is a "conversion" in digital marketing?', order: 2, explanation: 'A conversion is when a visitor completes a desired goal like a purchase or sign-up.',
          options: [{ text: 'When a user visits your website', isCorrect: false }, { text: 'When a visitor completes a desired action (e.g. purchase)', isCorrect: true }, { text: 'When an ad is shown to a user', isCorrect: false }, { text: 'When a social post goes viral', isCorrect: false }] },
        { text: 'Which metric shows visitors who leave after viewing only one page?', order: 3, explanation: 'Bounce rate = percentage of single-page sessions with no further interaction.',
          options: [{ text: 'Click-Through Rate', isCorrect: false }, { text: 'Bounce Rate', isCorrect: true }, { text: 'Conversion Rate', isCorrect: false }, { text: 'Engagement Rate', isCorrect: false }] },
        { text: 'In Google Ads, what does CPC stand for?', order: 4, explanation: 'CPC = Cost Per Click — the amount paid each time a user clicks an ad.',
          options: [{ text: 'Cost Per Campaign', isCorrect: false }, { text: 'Clicks Per Customer', isCorrect: false }, { text: 'Cost Per Click', isCorrect: true }, { text: 'Campaign Per Click', isCorrect: false }] },
        { text: 'What type of SEO focuses on factors outside your website?', order: 5, explanation: 'Off-page SEO includes link building and external signals that impact your rankings.',
          options: [{ text: 'On-Page SEO', isCorrect: false }, { text: 'Technical SEO', isCorrect: false }, { text: 'Off-Page SEO', isCorrect: true }, { text: 'Local SEO', isCorrect: false }] },
      ],
    },
  },
];

// ─── WRITE DOCUMENT ──────────────────────────────────────────────────────────

async function writeDoc(collPath, docId, data) {
  // Build field path list for updateMask
  const fieldPaths = Object.keys(data);
  const maskQuery = fieldPaths.map(f => `updateMask.fieldPaths=${encodeURIComponent(f)}`).join('&');
  const p = `${DB_PATH}/${collPath}/${docId}?${maskQuery}`;
  return request('PATCH', p, toFirestoreDoc(data));
}

// ─── SEED ONE COURSE ─────────────────────────────────────────────────────────

async function seedCourse(course) {
  process.stdout.write(`\n📚 ${course.data.title}\n`);

  // 1. Course document
  await writeDoc('courses', course.id, course.data);
  process.stdout.write('  ✅ course doc\n');

  // 2. Lessons as subcollection courses/{id}/videos
  for (const lesson of course.lessons) {
    const lessonId = `lesson_${course.id}_${String(lesson.order).padStart(2, '0')}`;
    await writeDoc(`courses/${course.id}/videos`, lessonId, {
      id: lessonId,
      title: lesson.title,
      videoUrl: lesson.contentUrl,
      videoURL: lesson.contentUrl,
      contentUrl: lesson.contentUrl,
      orderIndex: lesson.order,
      order: lesson.order,
      duration: lesson.duration,
      type: 'video',
      courseId: course.id,
      createdAt: NOW_ISO,
    });
    await sleep(80);
  }

  // 3. Lessons in top-level lessons collection
  for (const lesson of course.lessons) {
    const lessonId = `lesson_${course.id}_${String(lesson.order).padStart(2, '0')}`;
    await writeDoc('lessons', lessonId, {
      id: lessonId,
      title: lesson.title,
      type: 'video',
      contentUrl: lesson.contentUrl,
      videoUrl: lesson.contentUrl,
      courseId: course.id,
      moduleId: `module_${course.id}_01`,
      order: lesson.order,
      orderIndex: lesson.order,
      duration: lesson.duration,
      description: `Learn about: ${lesson.title}`,
      createdAt: NOW_ISO,
      updatedAt: NOW_ISO,
    });
    await sleep(80);
  }
  process.stdout.write(`  ✅ ${course.lessons.length} lessons\n`);

  // 4. Quiz
  const q = course.quiz;
  const quizId = `quiz_${course.id}`;
  await writeDoc('quizzes', quizId, {
    id: quizId,
    courseId: course.id,
    moduleId: `module_${course.id}_01`,
    title: q.title,
    description: q.description,
    passingScore: q.passingScore,
    maxAttempts: q.maxAttempts,
    timeLimit: q.timeLimit,
    status: 'published',
    createdAt: NOW_ISO,
    updatedAt: NOW_ISO,
  });

  for (const question of q.questions) {
    const qId = `${quizId}_q${question.order}`;
    await writeDoc(`quizzes/${quizId}/questions`, qId, {
      id: qId,
      quizId: quizId,
      text: question.text,
      order: question.order,
      explanation: question.explanation,
      createdAt: NOW_ISO,
    });
    await sleep(60);

    for (let i = 0; i < question.options.length; i++) {
      const optId = `${qId}_o${i + 1}`;
      await writeDoc(`quizzes/${quizId}/questions/${qId}/options`, optId, {
        id: optId,
        questionId: qId,
        text: question.options[i].text,
        isCorrect: question.options[i].isCorrect,
      });
      await sleep(60);
    }
  }
  process.stdout.write(`  ✅ quiz (${q.questions.length} questions)\n`);
  await sleep(200);
}

// ─── UPDATE EXISTING COURSES ─────────────────────────────────────────────────

async function updateExistingCourses() {
  process.stdout.write('\n🔍 Checking existing courses...\n');
  const docs = await getCollection('courses');
  const seededIds = new Set(COURSES.map(c => c.id));

  for (const doc of docs) {
    const docId = doc.name.split('/').pop();
    if (seededIds.has(docId)) continue;

    const fields = doc.fields || {};
    const getStr = (f) => fields[f]?.stringValue || '';
    const getBool = (f) => fields[f]?.booleanValue;

    const hasVideo = getStr('videoUrl') || getStr('videoURL');
    const updates = {};

    if (!hasVideo) {
      updates.videoUrl = 'https://www.youtube.com/watch?v=rfscVS0vtbw';
      updates.updatedAt = NOW_ISO;
    }
    if (!getBool('isPublished')) { updates.isPublished = true; updates.status = 'published'; updates.isApproved = true; updates.updatedAt = NOW_ISO; }

    if (Object.keys(updates).length > 0) {
      await writeDoc('courses', docId, updates);
      process.stdout.write(`  📹 Updated existing course: ${getStr('title') || docId}\n`);
      await sleep(200);
    }

    // Check and add quiz for existing course if missing
    const quizId = `quiz_${docId}`;
    try {
      await request('GET', `${DB_PATH}/quizzes/${quizId}`);
      // Quiz exists, skip
    } catch (e) {
      // Quiz doesn't exist, create a generic one
      const courseTitle = getStr('title') || 'Course';
      await writeDoc('quizzes', quizId, {
        id: quizId,
        courseId: docId,
        moduleId: '',
        title: `${courseTitle} – Knowledge Check`,
        description: 'Test your understanding of the key concepts in this course.',
        passingScore: 60,
        maxAttempts: 3,
        timeLimit: 10,
        status: 'published',
        createdAt: NOW_ISO,
        updatedAt: NOW_ISO,
      });

      const genericQs = [
        { id: `${quizId}_q1`, text: 'What was the primary focus of this course?', order: 1, explanation: 'Review the course introduction.', options: [{ text: 'Applying practical skills', isCorrect: true }, { text: 'Advanced mathematics', isCorrect: false }, { text: 'History and literature', isCorrect: false }, { text: 'Physical science', isCorrect: false }] },
        { id: `${quizId}_q2`, text: 'What is the best approach when learning a new technical skill?', order: 2, explanation: 'Practice and hands-on projects accelerate learning.', options: [{ text: 'Practice regularly with projects', isCorrect: true }, { text: 'Read theory only', isCorrect: false }, { text: 'Watch videos without notes', isCorrect: false }, { text: 'Memorize without understanding', isCorrect: false }] },
        { id: `${quizId}_q3`, text: 'Which of the following describes a key learning outcome of this course?', order: 3, explanation: 'Real-world application is a core learning outcome.', options: [{ text: 'Applying concepts to real-world scenarios', isCorrect: true }, { text: 'Memorizing historical dates', isCorrect: false }, { text: 'Drawing portraits', isCorrect: false }, { text: 'Cooking recipes', isCorrect: false }] },
      ];

      for (const gq of genericQs) {
        await writeDoc(`quizzes/${quizId}/questions`, gq.id, { id: gq.id, quizId, text: gq.text, order: gq.order, explanation: gq.explanation, createdAt: NOW_ISO });
        await sleep(60);
        for (let i = 0; i < gq.options.length; i++) {
          const oid = `${gq.id}_o${i + 1}`;
          await writeDoc(`quizzes/${quizId}/questions/${gq.id}/options`, oid, { id: oid, questionId: gq.id, text: gq.options[i].text, isCorrect: gq.options[i].isCorrect });
          await sleep(60);
        }
      }
      process.stdout.write(`  ✅ Quiz added for: ${courseTitle}\n`);
    }
  }
}

// ─── MAIN ─────────────────────────────────────────────────────────────────────

async function main() {
  console.log('🚀 Online Learning App – Firestore Seeder');
  console.log(`   Project: ${PROJECT_ID}\n`);

  try {
    await updateExistingCourses();

    for (const course of COURSES) {
      await seedCourse(course);
    }

    console.log('\n\n✅ Seeding complete!');
    console.log(`📊 ${COURSES.length} courses | ${COURSES.reduce((s, c) => s + c.lessons.length, 0)} lessons | ${COURSES.length} quizzes | ${COURSES.reduce((s, c) => s + c.quiz.questions.length, 0)} questions`);
  } catch (err) {
    console.error('\n❌ Error:', err.message);
    process.exit(1);
  }
}

main();
