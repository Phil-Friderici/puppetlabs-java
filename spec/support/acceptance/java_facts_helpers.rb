# frozen_string_literal: true

module JavaAcceptanceHelpers; end

module JavaAcceptanceHelpers::JavaFactsHelpers
  def default_java_major_version
    return debian_java_major_version if debian?
    return '21' if redhat? && os_release_major.to_i >= 10

    '8'
  end

  def java_package_name(distribution = 'jdk')
    return debian_java_package_name(distribution) if debian?
    return suse_java_package_name(distribution) if suse?

    default_java_package_name(distribution)
  end

  def debian_java_architecture
    { 'x86_64' => 'amd64', 'aarch64' => 'arm64', 'armv7l' => 'armhf' }.fetch(os_architecture, os_architecture)
  end

  def java_alternative
    "java-1.#{default_java_major_version}.0-openjdk-#{debian_java_architecture}"
  end

  def java_home
    return debian_java_home if debian?
    return suse_java_home if suse?

    default_java_home
  end

  def java_alternative_path
    "#{java_home}bin/java"
  end

  def archive_install_supported?
    (redhat? || debian?) && x86_64?
  end

  def archive_basedir
    redhat? ? '/usr/java' : '/usr/lib/jvm'
  end

  def java_version_pattern(major)
    (major.to_s == '8') ? %r{\A1\.8\.0(_\d+)?\z} : %r{\A#{Regexp.escape(major.to_s)}(\.\d+)*\z}
  end

  def java_binary_version(java_bin = 'java')
    target_shell("#{java_bin} -version 2>&1").stdout[%r{version "([^"]+)"}, 1]
  end

  def javac_binary_version(javac_bin = 'javac')
    target_shell("#{javac_bin} -version 2>&1").stdout[%r{javac (\S+)}, 1]
  end

  def java_facts
    JSON.parse(target_shell("puppet facts show #{JAVA_FACTS.join(' ')} --render-as json").stdout)
  end

  private

  def debian_java_major_version
    case os_release_major
    when '13', '26.04' then '21'
    when '12', '24.04' then '17'
    else '11'
    end
  end

  def debian_java_package_name(distribution)
    major = default_java_major_version
    (distribution == 'jre') ? "openjdk-#{major}-jre-headless" : "openjdk-#{major}-jdk"
  end

  def suse_java_package_name(distribution)
    (distribution == 'jre') ? 'java-1_8_0-openjdk' : 'java-1_8_0-openjdk-devel'
  end

  def default_java_package_name(distribution)
    major = default_java_major_version
    base = (major == '8') ? 'java-1.8.0-openjdk' : "java-#{major}-openjdk"
    (distribution == 'jre') ? base : "#{base}-devel"
  end

  def debian_java_home
    "/usr/lib/jvm/#{java_alternative}/"
  end

  def suse_java_home
    '/usr/lib64/jvm/java-1.8.0-openjdk-1.8.0/'
  end

  def default_java_home
    major = default_java_major_version
    (major == '8') ? '/usr/lib/jvm/java-1.8.0/' : "/usr/lib/jvm/java-#{major}-openjdk/"
  end
end
