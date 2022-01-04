using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using Telerik.Web.UI;

namespace GaziProje2014.Forms
{
    public partial class SinavSureOrnek : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            if (!IsPostBack)
            {
                DateTime bitisSure = Convert.ToDateTime("2014-05-02 01:40:00.000");
                double kalanSure = bitisSure.Subtract(DateTime.Now).TotalMinutes;

                //DateTime a = new DateTime(2010, 05, 12, 13, 15, 00);
                //DateTime b = new DateTime(2010, 05, 12, 13, 45, 00);
                //Console.WriteLine(b.Subtract(a).TotalMinutes);

                //set the expire timeout for the session
                //Session.Timeout = kalanSure;
                RadNotification1.ShowInterval = Convert.ToInt32(kalanSure);
                //configure the notification to automatically show 1 min before session expiration
                RadNotification1.ShowInterval = (Session.Timeout - 1) * 60000;
                //set the redirect url as a value for an easier and faster extraction in on the client
                RadNotification1.Value = Page.ResolveClientUrl("SessionExpired.aspx");
            }
        }

        protected void OnCallbackUpdate(object sender, RadNotificationEventArgs e)
        {

        }

    }
}