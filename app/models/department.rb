# frozen_string_literal: true
class Department < ListItem
  include CitiResourceMetadata

  class << self
    def options(hash = {})
      all.map { |d| hash[d.pref_label] = d.citi_uid }
      hash.sort.to_h
    end

    def find_by_department_key(key)
      where("citi_uid_ssim" => key).first
    end
  end
end
