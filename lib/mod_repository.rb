require_relative '../model/ark_mod'
module DalliAdapter
  class ModRepository
    def model_class
      ArkMod
    end

    def create(attributes={})
      new_record = model_class.new(attributes)
      if read_mod_list.find {|mod_info| mod_info.id == new_record.id }.nil?
        write_mod_list(read_mod_list << new_record)
      else
        raise 'A mod already exists with that ID! Maybe try to use the update method?'
      end
    end

    def find_by_id(mod_id)
      potential =  read_mod_list.select {|mod_info| mod_info.id == mod_id }
      if potential.count != 1
        raise "The mod you were looking for was not found! ID that was used in search: #{mod_id}"
      end
      potential.first
    end

    def update_by_id(mod_id)
      read_only_mod_info = find_by_id(mod_id)
      writable_mod_info  = find_by_id(mod_id)
      mod_list  = read_mod_list
      mod_index = mod_list.index(read_only_mod_info)
      yield(writable_mod_info)

      if writable_mod_info.id != read_only_mod_info.id || writable_mod_info.created_at != read_only_mod_info.created_at
        raise 'The mods ID and created at attributes are read only and should never be modified!'
      end

      writable_mod_info.updated_at = Time.now.utc.strftime('%m-%d-%Y %H:%M:%S')
      mod_list[mod_index] = writable_mod_info
      write_mod_list(mod_list)
    end

    def delete_by_id(mod_id)
      mod_info  = find_by_id(mod_id)
      mod_list  = read_mod_list
      write_mod_list(mod_list[mod_list.index(mod_info)])
    end

    def all
      read_mod_list
    end

    private
    def read_mod_list
      $dalli_cache.get('mod_list')
    end

    def write_mod_list(data)
      $dalli_cache.set('mod_list', data)
    end
  end
end