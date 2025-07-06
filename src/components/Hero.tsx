import { ArrowRight, Play } from 'lucide-react'

export default function Hero() {
  return (
    <section id="home" className="pt-20 section-padding bg-gradient-to-br from-blue-50 to-indigo-100">
      <div className="container-center">
        <div className="text-center">
          <div className="animate-fade-in">
            <h1 className="text-4xl sm:text-5xl lg:text-6xl font-bold text-gray-900 mb-6">
              Build Something
              <span className="text-blue-600 block">Amazing Today</span>
            </h1>
            <p className="text-xl text-gray-600 mb-8 max-w-2xl mx-auto leading-relaxed">
              Create beautiful, modern websites with cutting-edge technology. 
              Our platform provides everything you need to bring your vision to life.
            </p>
          </div>
          
          <div className="animate-slide-up flex flex-col sm:flex-row gap-4 justify-center items-center mb-12">
            <button className="btn-primary flex items-center gap-2">
              Get Started Free
              <ArrowRight size={20} />
            </button>
            <button className="btn-secondary flex items-center gap-2">
              <Play size={20} />
              Watch Demo
            </button>
          </div>

          <div className="animate-fade-in">
            <div className="relative max-w-4xl mx-auto">
              <div className="bg-white rounded-2xl shadow-2xl p-8 border border-gray-200">
                <div className="grid grid-cols-1 md:grid-cols-3 gap-8 text-center">
                  <div>
                    <div className="text-3xl font-bold text-blue-600 mb-2">50+</div>
                    <div className="text-gray-600">Modern Templates</div>
                  </div>
                  <div>
                    <div className="text-3xl font-bold text-blue-600 mb-2">99.9%</div>
                    <div className="text-gray-600">Uptime Guarantee</div>
                  </div>
                  <div>
                    <div className="text-3xl font-bold text-blue-600 mb-2">24/7</div>
                    <div className="text-gray-600">Support Available</div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>
  )
}