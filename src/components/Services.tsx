import { Check } from 'lucide-react'

export default function Services() {
  const services = [
    {
      name: 'Starter',
      price: '$29',
      description: 'Perfect for small projects',
      features: [
        '5 Pages',
        'Responsive Design',
        'Basic SEO',
        'Email Support',
        '1 GB Storage',
      ],
      popular: false,
    },
    {
      name: 'Professional',
      price: '$79',
      description: 'Ideal for growing businesses',
      features: [
        '20 Pages',
        'Advanced Design',
        'SEO Optimization',
        'Priority Support',
        '10 GB Storage',
        'Analytics Dashboard',
      ],
      popular: true,
    },
    {
      name: 'Enterprise',
      price: '$199',
      description: 'For large-scale applications',
      features: [
        'Unlimited Pages',
        'Custom Design',
        'Advanced SEO',
        '24/7 Support',
        'Unlimited Storage',
        'Advanced Analytics',
        'Custom Integrations',
      ],
      popular: false,
    },
  ]

  return (
    <section id="services" className="section-padding bg-white">
      <div className="container-center">
        <div className="text-center mb-16">
          <h2 className="text-3xl lg:text-4xl font-bold text-gray-900 mb-4">
            Choose Your Plan
          </h2>
          <p className="text-xl text-gray-600 max-w-2xl mx-auto">
            Flexible pricing options to suit your needs and budget.
          </p>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
          {services.map((service, index) => (
            <div
              key={index}
              className={`relative rounded-2xl border-2 p-8 ${
                service.popular
                  ? 'border-blue-500 shadow-xl scale-105'
                  : 'border-gray-200 hover:border-blue-300'
              } transition-all duration-300`}
            >
              {service.popular && (
                <div className="absolute -top-4 left-1/2 transform -translate-x-1/2">
                  <span className="bg-blue-500 text-white px-4 py-2 rounded-full text-sm font-medium">
                    Most Popular
                  </span>
                </div>
              )}
              
              <div className="text-center mb-8">
                <h3 className="text-2xl font-bold text-gray-900 mb-2">
                  {service.name}
                </h3>
                <p className="text-gray-600 mb-4">{service.description}</p>
                <div className="text-4xl font-bold text-gray-900 mb-2">
                  {service.price}
                  <span className="text-lg font-normal text-gray-600">/month</span>
                </div>
              </div>

              <ul className="space-y-4 mb-8">
                {service.features.map((feature, featureIndex) => (
                  <li key={featureIndex} className="flex items-center">
                    <Check className="w-5 h-5 text-green-500 mr-3" />
                    <span className="text-gray-700">{feature}</span>
                  </li>
                ))}
              </ul>

              <button
                className={`w-full py-3 px-6 rounded-lg font-medium transition-all duration-200 ${
                  service.popular
                    ? 'bg-blue-600 hover:bg-blue-700 text-white'
                    : 'bg-gray-100 hover:bg-gray-200 text-gray-900'
                }`}
              >
                Get Started
              </button>
            </div>
          ))}
        </div>
      </div>
    </section>
  )
}