# Selects current versions of products and attaches data
class CurrentProducts < Hash
  def initialize(pf_products, pf_metadata, pf_cat_entries, categories, assets)
    puts 'Identifying current products, adding metadata and categories'
    load_current_products pf_products, pf_cat_entries
    attach_metadata pf_metadata
    attach_categories pf_cat_entries, categories
    attach_assets pf_products, assets
  end

  private

  def load_current_products(pf_products, pf_cat_entries)
    pf_products.each do |p|
      # Add if there is a category entry for the product
      self[p[0]] = p[1] if pf_cat_entries.key? p[0]
      # Don't add if the product is marked as deleted
      delete p[0] if p[1][:b_IsDeleted] == 'True'
    end
  end

  def attach_metadata(metadata)
    values.each do |p|
      p.merge! metadata.fetch p[:ProductID__ID].to_sym, {}
    end
  end

  # Iterate over the list of category entries and attach the categories to each
  # product on self.
  def attach_categories(pf_cat_entries, categories)
    pf_cat_entries.each do |product_entries|
      # Skip unless the product is found in self
      next unless self[product_entries]

      product_entries[1].each_with_index do |category, i|
        # self = { product_id: { Category0: 'foo', Category1: 'bar' } } etc
        self[product_entries[0]]["Category#{i}".to_sym] =
          categories[category.to_sym][:Path]
      end
    end
  end

  def attach_assets(pf_products, pf_assets)
    pf_products.each do |p|
      asset = pf_assets[p[1][:ArchetypeAssetID__IDREF].to_sym]
      p[1][:assets_ShortName__STR] = asset[:ShortName__STR]
      p[1][:assets_FileLocation__STR] = asset[:FileLocation__STR]
    end
  end
end
