module Strongbolt
  class UserGroupsController < ::StrongboltController
  	def index
  		@user_groups = UserGroup.all
  	end

  	def show
      @user_group = UserGroup.find params[:id]
      # We select the users not yet in the user group
      @users = Strongbolt.user_class_constant
        .joins("LEFT JOIN strongbolt_user_groups_users sugu ON sugu.user_id = #{Strongbolt.user_class_constant.table_name}.id")
        .joins("LEFT JOIN strongbolt_user_groups sug ON sug.id = sugu.user_group_id")
        .where("sug.id IS NULL OR sug.id != ?", @user_group.id)
  	end

  	def create
      begin
        @user_group = UserGroup.create! user_group_params

        flash[:success] = "Use group was successfully created!"
        redirect_to user_group_path(@user_group)
      rescue ActiveRecord::RecordInvalid => e
        flash[:danger] = "User Group could not be created, please review the errors below"
        redirect_to new_user_group_path
      rescue ActionController::ParameterMissing => e
        flash[:danger] = "User Group could not be created: ERROR #{e}"
        redirect_to new_user_group_path
      end
  	end

  	def update
      begin
        @user_group = UserGroup.find params[:id]
        @user_group.update_attributes! user_group_params
        
        flash[:success] = "User group was successfully updated!"
        redirect_to user_group_path params[:id]
      rescue ActiveRecord::RecordInvalid => e
        flash[:danger] = "User Group could not be modified, please review the errors below"
        redirect_to edit_user_group_path(params[:id])
      rescue ActionController::ParameterMissing => e
        flash[:danger] = "User Group could not be updated: ERROR #{e}"
        redirect_to edit_user_group_path(params[:id])
      end
  	end

  	def destroy
      begin
        @user_group = UserGroup.find params[:id]
        @user_group.destroy!

        flash[:success] = "User group #{@user_group.name} successfully deleted"
        
        redirect_to user_groups_path
      rescue ActiveRecord::DeleteRestrictionError
        flash[:danger] = "User group #{@user_group.name} cannot be deleted because #{@user_group.users.size} users belong to it"

        redirect_to user_group_path(@user_group)
      end
  	end

  	def edit
      @user_group = UserGroup.find params[:id]
  	end

  	def new
      @user_group = UserGroup.new
  	end

    private

    def user_group_params
      params.require(:user_group).permit(:name, :role_ids => [])
    end
  end
end