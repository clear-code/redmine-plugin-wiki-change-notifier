Redmine::Plugin.register :wiki_change_notifier do
  name 'Wiki Change Notifier plugin'
  author 'Kouhei Sutou'
  description 'Notify Wiki change by e-mail'
  version '1.0.0'
  url 'https://github.com/kou/redmine-plugin-wiki-change-notifier'
  author_url 'https://github.com/kou/'
end

require "diff/lcs"
require "diff/lcs/hunk"
require "redmine/helpers/diff"

module UnifiedDiffable
  def to_unified_diff
    to_lines = content_to.text.to_s.lines.collect(&:chomp)
    from_lines = content_from.text.to_s.lines.collect(&:chomp)
    diffs = ::Diff::LCS.diff(from_lines, to_lines)

    unified_diff = ""

    old_hunk = nil
    n_lines = 3
    format = :unified
    file_length_difference = 0
    diffs.each do |piece|
      begin
        hunk = ::Diff::LCS::Hunk.new(from_lines, to_lines, piece, n_lines,
                                     file_length_difference)
        file_length_difference = hunk.file_length_difference

        next unless old_hunk

        if (n_lines > 0) and hunk.overlaps?(old_hunk)
          hunk.unshift(old_hunk)
        else
          unified_diff << old_hunk.diff(format)
        end
      ensure
        old_hunk = hunk
        unified_diff << "\n"
      end
    end

    unified_diff << old_hunk.diff(format)
    unified_diff << "\n"
    unified_diff
  end
end

class Redmine::Helpers::Diff
  include UnifiedDiffable
end

class WikiDiffNotifyListener < Redmine::Hook::ViewListener
  render_on :view_mailer_wiki_content_added_bottom,
            :partial => "wiki_change_notifier/show_content"
  render_on :view_mailer_wiki_content_updated_bottom,
            :partial => "wiki_change_notifier/unified_diff"
end
