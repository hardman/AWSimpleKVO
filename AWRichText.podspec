Pod::Spec.new do |s|
  s.name         = "AWSimpleKVO"
  s.version      = "1.0.0"
  s.summary      = "可用于替换系统KVO的简单KVO实现"
  s.description  = <<-DESC
解决系统KVO的问题：
1. 不支持block
2. 容易crash（忘记remove，重复remove等）
                   DESC
  s.homepage     = "https://github.com/hardman/AWSimpleKVO.git"
  s.license      = "MIT"
  s.author       = "wanghongyu"
  s.platform     = :ios, "8.0"
  s.source       = { :git => "https://github.com/hardman/AWSimpleKVO.git", :tag => "#{s.version}" }
  s.source_files  = "src/**/*.{h,m}"
  s.public_header_files = "src/**/*.h"
end
