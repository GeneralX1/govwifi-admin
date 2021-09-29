describe "Search Locations", type: :feature do
  let(:user) { create(:user, :with_organisation) }
  let(:organisation) { user.organisations.first }

  context "10 organisations with the same name, 1 different and alphabetically last" do
    before :each do
      FactoryBot.create_list(:location, 10, address: "BB123BB", postcode: "AA11AA", organisation: organisation)
      FactoryBot.create(:location, address: "QQQ123QQQ", postcode: "ZZ99ZZ", organisation: organisation)
      sign_in_user user
      visit ips_path
    end

    it "Does not filter anything if presented with a blank string" do
      fill_in "search", with: " "
      click_button("Search")
      expect(page).to have_content("AA11AA", minimum: 10)
      expect(page).not_to have_content("ZZ99ZZ")
    end

    it "Filters on postcodes that are not in the current page" do
      fill_in "search", with: "Z99Z"
      expect {
        click_button("Search")
      }.to change {
        page.has_content?("ZZ99ZZ")
      }.from(false).to(true)
    end

    it "Filters on addresses that are not in the current page" do
      fill_in "search", with: "Q12"
      expect {
        click_button("Search")
      }.to change {
        page.has_content?("ZZ99ZZ")
      }.from(false).to(true)
    end
  end
end
