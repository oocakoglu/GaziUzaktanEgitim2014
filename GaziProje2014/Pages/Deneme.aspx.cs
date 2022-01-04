using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using Telerik.Web.UI;

namespace GaziProje2014.Pages
{
    public partial class Deneme : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {

        }

        protected void RadGrid1_PreRender(object sender, EventArgs e)
        {

            //if (!overrideSelection)
            //{
            //    RadGrid1.MasterTableView.Items[0].Selected = true;
            //}
        }

       
        protected void RadGrid1_SelectedIndexChanged(object sender, EventArgs e)
        {
        
        }
 
        protected void RadGrid1_ItemUpdated(object source, Telerik.Web.UI.GridUpdatedEventArgs e)
        {
            
            GridEditableItem item = (GridEditableItem)e.Item;
            String id = item.GetDataKeyValue("FormId").ToString();

            //if (e.Exception != null)
            //{
            //    e.KeepInEditMode = true;
            //    e.ExceptionHandled = true;
            //    NotifyUser("Product with ID " + id + " cannot be updated. Reason: " + e.Exception.Message);
            //}
            //else
            //{
            //    NotifyUser("Product with ID " + id + " is updated!");
            //}

            ;
        }


 

   
    }
}