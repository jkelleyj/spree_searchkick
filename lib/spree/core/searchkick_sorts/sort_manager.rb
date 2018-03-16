module Spree
  module Core
    module SearchkickSorts
      class SortManager

        def initialize(params, taxon = nil)
          @params = params
          @taxon = taxon
        end

        def active_sort
          param_sort || default_sort
        end

        private

        def param_sort
          return unless @params[:sort]
          find_sort(@params[:sort])
        end

        def default_sort
          find_sort(default_sort_key)
        end

        def taxon_sort
          sort = {}
          sort[@taxon.sort_key.to_sym] = :asc

          { sort: [sort, { list_position: :asc }], label: 'Featured' }
        end


        def find_sort(sort_key)
          if @taxon && sort_key == 'featured'
            taxon_sort
          else
            SearchkickSorts::applicable_sorts[sort_key]
          end
        end


        def default_sort_key
          if @params[:keywords].blank?
            if @taxon && @taxon.respond_to?(:default_sort)
              @taxon.default_sort
            else
              'featured'
            end
          else
            'relevance'
          end
        end
      end
    end
  end
end
