module Spree::Search
  class Searchkick < Spree::Core::Search::Base
    def retrieve_products
      @products = get_base_elasticsearch
    end

    def get_base_elasticsearch
      curr_page = page || 1
      Spree::Product.search(keyword_query,
        where: where_query,
        aggs: aggregations,
        fields: ["name_and_brand^5", "name^4", "brand^2", "keywords^2", "description"],
        match: :word,
        includes: search_includes,
        smart_aggs: true,
        order: sorted,
        page: curr_page,
        per_page: per_page
      )
    end

    def where_query
      where_query = {
        active: true,
        currency: current_currency,
        price: {not: nil}
      }
      where_query.merge!({taxon_ids: taxon.id}) if taxon
      add_search_filters(where_query)
    end

    def keyword_query
      (keywords.nil? || keywords.empty?) ? "*" : keywords
    end

    def sorted
      @sort
    end

    def aggregations
      fs = {}
      Spree::Taxonomy.filterable.each do |taxonomy|
        fs[taxonomy.filter_name.to_sym] = {}
      end
      Spree::Property.filterable.each do |property|
        fs[property.filter_name.to_sym] = {}
      end
      fs[:brand] = {}
      fs[:price] = { ranges: [
        {to: 15},
        {to: 25},
        {to: 50},
        {to: 75},
        {to: 100},
        {from: 100}]
      }

      fs
    end

    def add_search_filters(query)
      return query unless search
      search.each do |name, scope_attribute|
        if name == 'price'
          price_filter = process_price(scope_attribute)
          query.merge!(price: price_filter)
        else
          query.merge!(Hash[name, scope_attribute])
        end
      end
      query
    end

    def search_includes
      @search_includes
    end

    def prepare(params)
      super
      @search_includes = params[:search_includes] || [master: [:images, :prices]]
      @sort = Spree::Core::SearchkickSorts.process_sorts(params, taxon)
    end

    def process_price(price_list)
      if price_list.any?
        from = nil
        to = nil
        price_list.each do |price|
          val = {}
          parts = price.split("-")
          unless parts.first == '*'
            from = [from, parts.first.to_f].compact.min
          end
          unless parts.second == '*'
            to = [parts.second.to_f, to].compact.max
          end
        end
        if from || to
          filter = {}
          filter[:gte] = from if from
          filter[:lte] = to if to
          filter
        end
      end
    end
  end
end
