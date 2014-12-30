module Strongbolt
  class RolesController < ::StrongboltController
    
    def index
      @roles = Role.includes(:parent)
        .order('parent_id IS NOT NULL', 'parent_id', 'name')
    end

    def new
      @role = Role.new
    end

    def show
      @role = Role.find params[:id]

      @capabilities = @role.capabilities.to_hash
      @inherited_capabilities = @role.inherited_capabilities.to_hash
      # All the models we have
      @keys = (@capabilities.keys | @inherited_capabilities.keys)

      @descendants = @role.descendants
    end

    def edit
      @role = Role.find params[:id]
    end

    def create
      begin
        @role = Role.create! role_params

        redirect_to role_path(@role)
      rescue ActiveRecord::RecordInvalid => e
        flash[:danger] = "Role could not be created, please review the errors below"
        redirect_to new_role_path
      rescue ActionController::ParameterMissing => e
        flash[:danger] = "Role could not be created: ERROR #{e}"
        redirect_to new_role_path
      rescue ActiveRecord::ActiveRecordError => e
        flash[:danger] = "The parent you selected leads to an impossible configuration"
        redirect_to edit_role_path(@role)
      end
    end

    def update
      begin
        @role = Role.find params[:id]
        @role.update_attributes! role_params

        redirect_to role_path(@role)
      rescue ActiveRecord::RecordInvalid => e
        flash[:danger] = "Role could not be updated, please review the errors below"
        redirect_to edit_role_path(@role)
      rescue ActionController::ParameterMissing => e
        flash[:danger] = "Role could not be updated: ERROR #{e}"
        redirect_to edit_role_path(@role)
      rescue ActiveRecord::ActiveRecordError => e
        flash[:danger] = "The parent you selected leads to an impossible configuration"
        redirect_to edit_role_path(@role)
      end
    end

    def destroy
      begin
        @role = Role.find params[:id]
        @role.destroy!

        flash[:success] = "Role #{@role.name} successfully deleted"

        redirect_to roles_path
      rescue ActiveRecord::DeleteRestrictionError
        flash[:danger] = "Role #{@role.name} could not be deleted because #{@role.user_groups.size} user groups rely on it"
        redirect_to role_path(@role)
      end
    end

    rescue_from ActiveRecord::RecordNotFound do |e|
      flash[:danger] = "Could not find role."
      redirect_to roles_path
    end

    private

    def role_params
      params.require(:role).permit(:name, :parent_id, :description,
        :capability_ids => [])
    end

  end
end