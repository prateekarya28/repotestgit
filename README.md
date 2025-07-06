# Modern Website

A beautiful, modern website built with React, TypeScript, and Tailwind CSS.

## Features

- **Modern Design**: Clean, professional design with smooth animations
- **Responsive**: Works perfectly on all devices and screen sizes
- **Fast**: Built with Vite for lightning-fast development and builds
- **TypeScript**: Type-safe code for better development experience
- **Tailwind CSS**: Utility-first CSS framework for rapid styling
- **Accessible**: Built with accessibility best practices

## Getting Started

### Prerequisites

- Node.js 18+ 
- npm or yarn

### Installation

1. Clone the repository:
```bash
git clone <your-repo-url>
cd modern-website
```

2. Install dependencies:
```bash
npm install
```

3. Start the development server:
```bash
npm run dev
```

4. Open your browser and visit `http://localhost:3000`

### Building for Production

```bash
npm run build
```

The built files will be in the `dist` directory.

### Preview Production Build

```bash
npm run preview
```

## Project Structure

```
src/
├── components/          # React components
│   ├── Header.tsx      # Navigation header
│   ├── Hero.tsx        # Hero section
│   ├── Features.tsx    # Features showcase
│   ├── About.tsx       # About section
│   ├── Services.tsx    # Services/pricing
│   ├── Contact.tsx     # Contact form
│   └── Footer.tsx      # Footer
├── App.tsx             # Main app component
├── main.tsx           # App entry point
└── index.css          # Global styles

```

## Tech Stack

- **React 18** - UI library
- **TypeScript** - Type safety
- **Vite** - Build tool
- **Tailwind CSS** - Styling
- **Lucide React** - Icons

## Customization

### Colors
The primary color scheme uses blue tones. You can customize colors in `tailwind.config.js`.

### Content
Update the content in each component file to match your needs:
- Company name in `Header.tsx` and `Footer.tsx`
- Hero content in `Hero.tsx`
- Features in `Features.tsx`
- About information in `About.tsx`
- Services/pricing in `Services.tsx`
- Contact details in `Contact.tsx`

### Styling
All styles use Tailwind CSS classes. Custom component styles are defined in `src/index.css`.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## License

This project is licensed under the MIT License.