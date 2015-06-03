module CodeClimate
  module TestReporter
    class Git

      class << self
        def info
          if not ENV['GIT_HEAD'] or not ENV['GIT_COMMITTED_AT'] or not ENV['GIT_BRANCH_FROM']
            puts "ENV['GIT_HEAD'] = "+ENV['GIT_HEAD'].to_s+"  ENV['GIT_COMMITTED_AT'] = "+ENV['GIT_COMMITTED_AT'].to_s + "  ENV['GIT_BRANCH_FROM'] = "+ENV['GIT_BRANCH_FROM'].to_s
            puts "Warning you have not set ENV['GIT_HEAD'], ENV['GIT_COMMITTED_AT'] and ENV['GIT_BRANCH_FROM']. This is a custom library and you need to set these env vars or you need to pass the entire .git directory into your docker container."
            git_data = {
              head:         head,
              committed_at: committed_at,
              branch:       branch_from_git,
            }
            return git_data
          else
            git_data = {
              head:		ENV['GIT_HEAD'],
              committed_at:	ENV['GIT_COMMITTED_AT'].to_i,
              branch:		ENV['GIT_BRANCH_FROM'],
            }
            return git_data
          end
        end

        def branch_from_git_or_ci
          clean_service_branch || clean_git_branch || "master"
        end

        def clean_service_branch
          ci_branch = String(Ci.service_data[:branch])
          clean = ci_branch.strip.sub(/^origin\//, "")

          clean.size > 0 ? clean : nil
        end

        def clean_git_branch
          git_branch = String(branch_from_git)
          clean = git_branch.sub(/^origin\//, "") unless git_branch.start_with?("(")

          clean.size > 0 ? clean : nil
        end

        private

        def head
          git("log -1 --pretty=format:'%H'")
        end

        def committed_at
          committed_at = git('log -1 --pretty=format:%ct')
          committed_at.to_i.zero? ? nil : committed_at.to_i
        end

        def branch_from_git
          git('rev-parse --abbrev-ref HEAD').chomp
        end

        def git(command)
          `git --git-dir="#{git_dir}/.git" #{command}`
        end

        def git_dir
          return configured_git_dir unless configured_git_dir.nil?
          rails_git_dir_present? ? Rails.root : '.'
        end

        def configured_git_dir
          CodeClimate::TestReporter.configuration.git_dir
        end

        def rails_git_dir_present?
          const_defined?(:Rails) && Rails.respond_to?(:root) && !Rails.root.nil? &&
            File.directory?(File.expand_path('.git', Rails.root))
        end
      end
    end
  end
end

