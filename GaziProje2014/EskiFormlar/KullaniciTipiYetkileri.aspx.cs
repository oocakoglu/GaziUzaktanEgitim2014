using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using Telerik.Web.UI;

namespace GaziProje2014.Forms
{
    public partial class KullaniciTipiYetkileri : System.Web.UI.Page
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

        protected void RadGridKullaniciTipleri_DataBound(object sender, EventArgs e)
        {

        }

        protected void RadGridKullaniciTipleri_ItemDataBound(object sender, GridItemEventArgs e)
        {

        }

        protected void grdYetkiler_ItemDataBound(object sender, GridItemEventArgs e)
        {
            if (e.Item is GridGroupHeaderItem)
            {
                string imageUrl = ((System.Data.DataRowView)(e.Item.DataItem)).Row.ItemArray[0].ToString();            
                GridGroupHeaderItem hitem = (GridGroupHeaderItem)e.Item;
                Image img = (Image)hitem.FindControl("imgResim");
                img.ImageUrl = imageUrl;
            }
        }
    }
}