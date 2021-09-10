describe "View and search locations", type: :feature do
  let(:user) { create(:user, :super_admin) }
  let(:organisation) { create(:organisation) }

  before do
    create(:location, address: "69 Garry Street, London", postcode: "HA7 2BL", organisation: organisation)
    sign_in_user user
    visit root_path
    within(".leftnav") { click_on "Locations" }
  end

  it "takes the user to the locations page" do
    expect(page).to have_content("GovWifi locations")
  end

  context "with all the locations details" do
    it "lists the full address of the location" do
      expect(page).to have_content("69 Garry Street, London, HA7 2BL")
    end

    it "lists the organisation the location belongs to" do
      expect(page).to have_content(organisation.name)
    end
  end

  context "select an organisation with 41 locations" do
    before :each do
      FactoryBot.create_list(:location, 40, organisation: organisation)
      click_on organisation.name
    end
    it "shows 5 pages, a 'Next' link but not a 'Prev' link" do
      expect(page).to_not have_content "Prev"
      expect(page).to have_content(/1\s*2\s*3\s*4\s*5\s*Next/).twice
    end
    it "shows 5 pages, a 'Next' link and a 'Prev' link" do
      within(".pager__controls", match: :first) { click_on "3" }
      expect(page).to have_content(/Prev\s*1\s*2\s*3\s*4\s*5\s*Next/).twice
    end
    it "shows 5 pages, a 'Prev' link but not a 'Next' link" do
      within(".pager__controls", match: :first) { click_on "5" }
      expect(page).to_not have_content "Next"
      expect(page).to have_content(/Prev\s*1\s*2\s*3\s*4\s*5/).twice
    end
  end
end
