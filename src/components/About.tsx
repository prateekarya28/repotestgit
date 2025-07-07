import { Users, Award, Target } from 'lucide-react'

export default function About() {
  return (
    <section id="about" className="section-padding bg-gray-50">
      <div className="container-center">
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-12 items-center">
          <div>
            <h2 className="text-3xl lg:text-4xl font-bold text-gray-900 mb-6">
              About Our Company
            </h2>
            <p className="text-lg text-gray-600 mb-6 leading-relaxed">
              We're a team of passionate developers and designers dedicated to creating 
              exceptional digital experiences. With years of expertise in modern web 
              technologies, we help businesses transform their ideas into reality.
            </p>
            <p className="text-lg text-gray-600 mb-8 leading-relaxed">
              Our mission is to provide cutting-edge solutions that not only meet your 
              current needs but also scale with your future growth.
            </p>
            
            <div className="grid grid-cols-1 sm:grid-cols-3 gap-6">
              <div className="text-center">
                <div className="bg-blue-100 w-16 h-16 rounded-full flex items-center justify-center mx-auto mb-3">
                  <Users className="w-8 h-8 text-blue-600" />
                </div>
                <div className="text-2xl font-bold text-gray-900">500+</div>
                <div className="text-gray-600">Happy Clients</div>
              </div>
              <div className="text-center">
                <div className="bg-blue-100 w-16 h-16 rounded-full flex items-center justify-center mx-auto mb-3">
                  <Award className="w-8 h-8 text-blue-600" />
                </div>
                <div className="text-2xl font-bold text-gray-900">50+</div>
                <div className="text-gray-600">Awards Won</div>
              </div>
              <div className="text-center">
                <div className="bg-blue-100 w-16 h-16 rounded-full flex items-center justify-center mx-auto mb-3">
                  <Target className="w-8 h-8 text-blue-600" />
                </div>
                <div className="text-2xl font-bold text-gray-900">1000+</div>
                <div className="text-gray-600">Projects Done</div>
              </div>
            </div>
          </div>
          
          <div className="relative">
            <div className="bg-white rounded-2xl shadow-xl p-8 border border-gray-200">
              <h3 className="text-2xl font-bold text-gray-900 mb-6">Our Values</h3>
              <div className="space-y-4">
                <div className="flex items-start space-x-4">
                  <div className="w-2 h-2 bg-blue-600 rounded-full mt-3"></div>
                  <div>
                    <h4 className="font-semibold text-gray-900 mb-1">Innovation</h4>
                    <p className="text-gray-600">We stay ahead of the curve with the latest technologies.</p>
                  </div>
                </div>
                <div className="flex items-start space-x-4">
                  <div className="w-2 h-2 bg-blue-600 rounded-full mt-3"></div>
                  <div>
                    <h4 className="font-semibold text-gray-900 mb-1">Quality</h4>
                    <p className="text-gray-600">Every project is crafted with attention to detail.</p>
                  </div>
                </div>
                <div className="flex items-start space-x-4">
                  <div className="w-2 h-2 bg-blue-600 rounded-full mt-3"></div>
                  <div>
                    <h4 className="font-semibold text-gray-900 mb-1">Support</h4>
                    <p className="text-gray-600">We're here for you every step of the way.</p>
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