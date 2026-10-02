# frozen_string_literal: true

require 'spec_helper_acceptance'

describe 'java class distribution variants' do
  let(:expected_java_version) { java_version_pattern(default_java_major_version) }

  context 'with distribution => jre' do
    before(:all) do
      apply_manifest(java_class_manifest(distribution: 'jre'), catch_failures: true)
    end

    it_behaves_like 'an idempotent manifest' do
      let(:manifest) { java_class_manifest(distribution: 'jre') }
    end

    it_behaves_like 'an installed java package' do
      let(:package_name) { java_package_name('jre') }
    end

    it_behaves_like 'a working java binary' do
      let(:java_bin) { 'java' }
    end
  end

  context 'with distribution => jdk' do
    before(:all) do
      apply_manifest(java_class_manifest(distribution: 'jdk'), catch_failures: true)
    end

    it_behaves_like 'an idempotent manifest' do
      let(:manifest) { java_class_manifest(distribution: 'jdk') }
    end

    it_behaves_like 'an installed java package' do
      let(:package_name) { java_package_name('jdk') }
    end

    it_behaves_like 'a working java binary' do
      let(:java_bin) { 'java' }
    end

    it_behaves_like 'a java development kit' do
      let(:javac_bin) { 'javac' }
    end
  end

  context 'with an unsupported distribution' do
    it 'fails with a meaningful error' do
      result = apply_manifest(java_class_manifest(distribution: 'xyz'), expect_failures: true)
      expect(result.stderr).to match(%r{Java distribution xyz is not supported})
    end
  end
end
