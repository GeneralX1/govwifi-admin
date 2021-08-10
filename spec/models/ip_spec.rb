describe Ip do
  subject(:ip_address) { described_class.new }

  it { is_expected.to belong_to(:location) }
  it { is_expected.to validate_presence_of(:address) }
  it { is_expected.to validate_uniqueness_of(:address) }

  # rubocop:disable Rails/SaveBang
  context "when validating address" do
    let(:location) { create(:location, organisation: create(:organisation)) }

    it "does not allow the address 0.0.0.0" do
      ip = described_class.create(address: "0.0.0.0", location: location)
      expect(ip.errors.full_messages).to eq([
        "Address '0.0.0.0' is not a valid IP address",
      ])
    end

    it "does not allow a blank address" do
      ip = described_class.create(address: "", location: location)
      expect(ip.errors.full_messages).to eq([
        "Address can't be blank",
      ])
    end

    context "with an invalid address" do
      let!(:ip) { described_class.create(address: "invalidIP", location: location) }

      it "does not save" do
        expect(described_class.count).to eq(0)
      end

      it "displays an error message" do
        expect(ip.errors.full_messages).to eq([
          "Address 'invalidIP' is not a valid IP address",
        ])
      end
    end

    context "with a valid IPv4 address" do
      let!(:ip) { described_class.create(address: "141.0.149.130", location: location) }

      it "saves the IP" do
        expect(described_class.count).to eq(1)
      end

      it "does not display an an error message" do
        expect(ip.errors.full_messages).to eq([])
      end
    end

    context "with a valid IPv6 address" do
      let!(:ip) { described_class.create(address: "2001:db8:0:1234:0:567:8:1", location: location) }

      it "does not save the IP" do
        expect(described_class.count).to eq(0)
      end

      it "displays an error message" do
        expect(ip.errors.full_messages).to eq([
          "Address '2001:db8:0:1234:0:567:8:1' is an IPv6 address. Only IPv4 addresses can be added.",
        ])
      end
    end

    context "with a private address" do
      let!(:ip) { described_class.create(address: "192.168.0.0", location: location) }

      it "does not save the IP" do
        expect(described_class.count).to eq(0)
      end

      it "displays an error message" do
        expect(ip.errors.full_messages).to eq([
          "Address '192.168.0.0' is a private IP address. Only public IPv4 addresses can be added.",
        ])
      end
    end
  end
  # rubocop:enable Rails/SaveBang

  context "when checking availability" do
    context "with an IP created at or after the midnight restart" do
      before { ip_address.created_at = Time.zone.today.beginning_of_day }

      it { is_expected.not_to be_available }
    end

    context "with an IP created before the midnight restart" do
      before { ip_address.created_at = Time.zone.today.beginning_of_day - 1.second }

      it { is_expected.to be_available }
    end
  end

  context "when checking if inactive" do
    context "with no sessions for the last 10 days" do
      before do
        create(:session, start: Time.zone.today - 11.days, username: "abc123", siteIP: ip_address.address)
      end

      it { is_expected.to be_inactive }
    end

    context "with sessions in the last 10 days" do
      before do
        create(:session, start: Time.zone.today, username: "abc123", siteIP: ip_address.address)
      end

      it { is_expected.not_to be_inactive }
    end
  end

  context "when checking if unused" do
    context "with an IP which has activity" do
      before do
        create(:session, start: Time.zone.today, username: "abc123", siteIP: ip_address.address)
      end

      it { is_expected.not_to be_unused }
    end

    context "with an IP which has no activity" do
      it { is_expected.to be_unused }
    end
  end

  describe "#percent_success" do
    context "No sessions" do
      it "returns 0" do
        expect(ip_address.percent_success).to eq(0)
      end
    end
    context "Only successes" do
      it "calculates 100% success" do
        create_list(:session, 3, success: true, siteIP: ip_address.address, start: Time.zone.today)
        expect(ip_address.percent_success).to eq(100)
      end
    end
    context "3 successes, 2 failures" do
      before :each do
        create_list(:session, 3, success: true, siteIP: ip_address.address, start: Time.zone.today)
        create_list(:session, 2, success: false, siteIP: ip_address.address, start: Time.zone.today)
      end
      it "calculates 3 success, 2 failed = 60%" do
        expect(ip_address.percent_success).to eq(60)
      end
      it "ignores sessions older than 1 day" do
        create_list(:session, 2, success: true, siteIP: ip_address.address, start: Time.zone.today - 2.days)
        create_list(:session, 2, success: false, siteIP: ip_address.address, start: Time.zone.today - 2.days)
        expect(ip_address.percent_success).to eq(60)
      end
      it "ignores sessions with a different IP address" do
        create_list(:session, 2, success: true, siteIP: "4.5.6.7", start: Time.zone.today)
        create_list(:session, 2, success: false, siteIP: "4.5.6.7", start: Time.zone.today)
        expect(ip_address.percent_success).to eq(60)
      end
    end
  end
end
