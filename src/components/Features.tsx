import { Zap, Shield, Smartphone, Code, Globe, HeartHandshake } from 'lucide-react'

export default function Features() {
  const features = [
    {
      icon: <Zap className="w-8 h-8" />,
      title: 'Lightning Fast',
      description: 'Optimized for speed with cutting-edge performance techniques.',
    },
    {
      icon: <Shield className="w-8 h-8" />,
      title: 'Secure by Default',
      description: 'Enterprise-grade security built into every aspect of our platform.',
    },
    {
      icon: <Smartphone className="w-8 h-8" />,
      title: 'Mobile First',
      description: 'Responsive design that looks perfect on every device.',
    },
    {
      icon: <Code className="w-8 h-8" />,
      title: 'Developer Friendly',
      description: 'Clean code, modern frameworks, and excellent documentation.',
    },
    {
      icon: <Globe className="w-8 h-8" />,
      title: 'Global CDN',
      description: 'Content delivered fast from servers around the world.',
    },
    {
      icon: <HeartHandshake className="w-8 h-8" />,
      title: '24/7 Support',
      description: 'Expert support team ready to help you succeed.',
    },
  ]

  return (
    <section id="features" className="section-padding bg-white">
      <div className="container-center">
        <div className="text-center mb-16">
          <h2 className="text-3xl lg:text-4xl font-bold text-gray-900 mb-4">
            Why Choose Our Platform?
          </h2>
          <p className="text-xl text-gray-600 max-w-2xl mx-auto">
            Built with modern technology and best practices to give you the edge you need.
          </p>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8">
          {features.map((feature, index) => (
            <div
              key={index}
              className="group p-6 rounded-xl border border-gray-200 hover:border-blue-300 hover:shadow-lg transition-all duration-300 bg-white"
            >
              <div className="text-blue-600 mb-4 group-hover:scale-110 transition-transform duration-200">
                {feature.icon}
              </div>
              <h3 className="text-xl font-semibold text-gray-900 mb-3">
                {feature.title}
              </h3>
              <p className="text-gray-600 leading-relaxed">
                {feature.description}
              </p>
            </div>
          ))}
        </div>
      </div>
    </section>
  )
}