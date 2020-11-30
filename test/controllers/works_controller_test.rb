require "test_helper"

describe WorksController do
  let(:existing_work) { works(:album) }

  before do
    perform_login(users(:dan))
  end

  describe "root" do
    it "succeeds with all media types" do
      get root_path

      must_respond_with :success
    end

    it "succeeds with one media type absent" do
      only_book = works(:poodr)
      only_book.destroy

      get root_path

      must_respond_with :success
    end

    it "succeeds with no media" do
      Work.all do |work|
        work.destroy
      end

      get root_path

      must_respond_with :success
    end
  end

  CATEGORIES = %w(albums books movies)
  INVALID_CATEGORIES = ["nope", "42", "", "  ", "albumstrailingtext"]

  describe "index" do
    it "succeeds when there are works" do
      get works_path

      must_respond_with :success
    end

    it "succeeds when there are no works" do
      Work.all do |work|
        work.destroy
      end

      get works_path

      must_respond_with :success
    end
  end

  describe "new" do
    it "succeeds" do
      get new_work_path

      must_respond_with :success
    end
  end

  describe "create" do
    it "creates a work with valid data for a real category" do
      new_work = { work: { title: "Dirty Computer", category: "album" } }

      expect {
        post works_path, params: new_work
      }.must_change "Work.count", 1

      new_work_id = Work.find_by(title: "Dirty Computer").id

      must_respond_with :redirect
      must_redirect_to work_path(new_work_id)
    end

    it "renders bad_request and does not update the DB for bogus data" do
      bad_work = { work: { title: nil, category: "book" } }

      expect {
        post works_path, params: bad_work
      }.wont_change "Work.count"

      must_respond_with :bad_request
    end

    it "renders 400 bad_request for bogus categories" do
      INVALID_CATEGORIES.each do |category|
        invalid_work = { work: { title: "Invalid Work", category: category } }

        expect { post works_path, params: invalid_work }.wont_change "Work.count"

        expect(Work.find_by(title: "Invalid Work", category: category)).must_be_nil
        must_respond_with :bad_request
      end
    end
  end

  describe "show" do
    it "succeeds for an extant work ID" do
      get work_path(existing_work.id)

      must_respond_with :success
    end

    it "renders 404 not_found for a bogus work ID" do
      destroyed_id = existing_work.id
      existing_work.destroy

      get work_path(destroyed_id)

      must_respond_with :not_found
    end
  end

  describe "edit" do
    it "succeeds for an extant work ID" do
      get edit_work_path(existing_work.id)

      must_respond_with :success
    end

    it "renders 404 not_found for a bogus work ID" do
      bogus_id = existing_work.id
      existing_work.destroy

      get edit_work_path(bogus_id)

      must_respond_with :not_found
    end
  end

  describe "update" do
    it "succeeds for valid data and an extant work ID" do
      updates = { work: { title: "Dirty Computer" } }

      expect {
        put work_path(existing_work), params: updates
      }.wont_change "Work.count"
      updated_work = Work.find_by(id: existing_work.id)

      expect(updated_work.title).must_equal "Dirty Computer"
      must_respond_with :redirect
      must_redirect_to work_path(existing_work.id)
    end

    it "renders bad_request for bogus data" do
      updates = { work: { title: nil } }

      expect {
        put work_path(existing_work), params: updates
      }.wont_change "Work.count"

      work = Work.find_by(id: existing_work.id)

      must_respond_with :not_found
    end

    it "renders 404 not_found for a bogus work ID" do
      bogus_id = existing_work.id
      existing_work.destroy

      put work_path(bogus_id), params: { work: { title: "Test Title" } }

      must_respond_with :not_found
    end
  end

  describe "destroy" do
    it "succeeds for an extant work ID" do
      expect {
        delete work_path(existing_work.id)
      }.must_change "Work.count", -1

      must_respond_with :redirect
      must_redirect_to root_path
    end

    it "renders 404 not_found and does not update the DB for a bogus work ID" do
      bogus_id = existing_work.id
      existing_work.destroy

      expect {
        delete work_path(bogus_id)
      }.wont_change "Work.count"

      must_respond_with :not_found
    end
  end

  describe "upvote" do


    it "redirects to the work page if no user is logged in" do
    delete logout_path

      expect {
        post upvote_path(works(:poodr))
      }.wont_change "Vote.count"

      expect(flash[:result_text]).must_equal "You must be logged in to do that!"

    end

    it "redirects to the work page after the user has logged out" do
      delete logout_path

      must_respond_with :redirect
      must_redirect_to root_path
    end

    it "succeeds for a logged-in user and a fresh user-vote pair" do
      expect {
        post upvote_path(works(:poodr))
      }.must_change "Vote.count", 1

      expect(flash[:status]).must_equal :success
      expect(flash[:result_text]).must_equal "Successfully upvoted!"
    end

    it "redirects to the work page if the user has already voted for that work" do

      post upvote_path(works(:album))

      expect {
        post upvote_path(works(:album))
      }.wont_change "Vote.count"


      expect(flash[:result_text]).must_equal "Could not upvote"
    end
  end

  describe "require login" do
    it "redirects a guest user who tries to access show page" do
      delete logout_path
      get work_path(works(:album).id)

      must_respond_with :redirect
      expect(flash[:status]).must_equal :failure
      expect(flash[:result_text]).must_equal "You must be logged in to do that!"
    end

    it "redirects a guest user who tries to upvote" do
      delete logout_path
      expect {
        post upvote_path(works(:poodr))
      }.wont_change "Vote.count"

      must_respond_with :redirect
      expect(flash[:status]).must_equal :failure
      expect(flash[:result_text]).must_equal "You must be logged in to do that!"
    end

    it "redirects a guest user who tries to add new work" do
      delete logout_path
      get new_work_path

      must_respond_with :redirect
      expect(flash[:status]).must_equal :failure
      expect(flash[:result_text]).must_equal "You must be logged in to do that!"
    end

    it "redirects a guest user who tries to delete a work" do
      delete logout_path
      delete work_path(works(:poodr))

      must_respond_with :redirect
      expect(flash[:status]).must_equal :failure
      expect(flash[:result_text]).must_equal "You must be logged in to do that!"
    end
  end

  # describe "Authorization" do
  #
  #   before do
  #     user = perform_login(users(:dan))
  #   end
  #
  #   it "Authorized merchants can access edit page for their own works" do
  #     get edit_work_path(works(:album).id)
  #
  #     must_respond_with :success
  #   end
  #
  #   it "Should not render edit page for invalid work ID" do
  #     get edit_work_path(-1)
  #     must_respond_with :not_found
  #   end
  #
  #   it "Authorized merchants can update their own works" do
  #     update_hash = {
  #         work: {
  #             title: "bookie",
  #             category: "book"
  #         }
  #     }
  #
  #     patch work_path(works(:album).id),  params: update_hash
  #
  #     updated_work = Product.find_by(name: "bookie")
  #     expect(updated_work.name).must_equal "bookie"
  #     expect(updated_work).must_equal works(:album)
  #
  #     must_respond_with :found
  #     must_redirect_to work_path(works(:album).id)
  #   end
  #
  #   it "will not update work with invalid params" do
  #     patch work_path(works(:album).id), params: { work: { name: "" } }
  #
  #     must_respond_with :bad_request
  #   end
  #
  #   it "Authorized merchants can delete their own works" do
  #
  #     expect{
  #       delete work_path(works(:album).id)
  #     }.must_change "Work.count", -1
  #
  #     deleted_work = Work.find_by(name: "album")
  #
  #     expect(deleted_work).must_be_nil
  #     must_respond_with :redirect
  #
  #   end
  #
  #   it "users can't access edit page for works they don't own" do
  #
  #     get edit_work_path(works(:another_album).id) # valentine's work
  #     expect(flash[:status]).must_equal :failure
  #     must_respond_with :redirect
  #   end
  #
  #   it "merchants can't delete works they don't own" do
  #     k_work_count = users(:kari).works.count
  #
  #     # dan tries to delete kari's work
  #
  #     expect{
  #       delete work_path(works(:another_album).id)
  #     }.wont_change k_work_count
  #
  #     must_respond_with :redirect
  #   end
  # end
end
