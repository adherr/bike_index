require "rails_helper"

RSpec.describe "organizations routing", type: :routing do
  describe "landing_pages" do
    it "routes root to " do
      expect(LandingPages::ORGANIZATIONS).to include("university")
      expect(get: "/university").to route_to(
        controller: "landing_pages",
        organization_id: "university",
        action: "show"
      )
    end
  end
  describe "organized module" do # At least for now...
    describe "root" do
      it "routes to base index action" do
        expect(get: "/o/university").to route_to(
          controller: "organized/dashboard",
          action: "root",
          organization_id: "university"
        )
      end
    end
    describe "dashboard" do
      it "routes to base index action" do
        expect(get: "/o/university/dashboard").to route_to(
          controller: "organized/dashboard",
          action: "index",
          organization_id: "university"
        )
      end
    end
    describe "users" do
      it "routes to users" do
        expect(get: "/o/university/users/new").to route_to(
          controller: "organized/users",
          action: "new",
          organization_id: "university"
        )
      end
    end
    describe "manage root" do
      it "routes to manage" do
        expect(get: "/o/university/manage").to route_to(
          controller: "organized/manages",
          action: "show",
          organization_id: "university"
        )
      end
    end
    describe "manage locations" do
      it "routes to manage" do
        expect(get: "/o/university/manage/locations").to route_to(
          controller: "organized/manages",
          action: "locations",
          organization_id: "university"
        )
      end
    end
  end

  context "legacy embed" do
    describe "embed" do
      it "routes to organizations#embed" do
        expect(get: "/organizations/bike_store/embed").to route_to(
          controller: "organizations",
          action: "embed",
          id: "bike_store"
        )
      end
    end
    describe "embed_extended" do
      it "routes to organizations#embed" do
        expect(get: "/organizations/cool_cats/embed_extended").to route_to(
          controller: "organizations",
          action: "embed_extended",
          id: "cool_cats"
        )
      end
    end
  end
  context "organizations new" do
    it "routes to organizations new" do
      expect(get: "/organizations/new").to route_to(
        controller: "organizations",
        action: "new"
      )
    end
  end

  describe "org_public module" do # At least for now...
    it "routes to impounded_bikes" do
      expect(get: "/hogwarts/impounded_bikes").to route_to(
        controller: "org_public/impounded_bikes",
        action: "index",
        organization_id: "hogwarts"
      )
    end
  end
end
