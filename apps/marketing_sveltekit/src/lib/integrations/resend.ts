import { Resend } from 'resend';

const resend = new Resend(process.env.RESEND_API_KEY);
const FROM_EMAIL = process.env.FROM_EMAIL || 'noreply@yourdomain.com';

export class EmailService {
  /**
   * Send registration confirmation email to company owner
   */
  static async sendRegistrationConfirmation(
    email: string,
    data: {
      businessName: string;
      ownerName: string;
      dashboardUrl: string;
    }
  ) {
    try {
      const { data: result, error } = await resend.emails.send({
        from: FROM_EMAIL,
        to: email,
        subject: `Welcome to ${data.businessName} - Registration Successful`,
        html: `
          <!DOCTYPE html>
          <html>
            <head>
              <meta charset="utf-8">
              <meta name="viewport" content="width=device-width, initial-scale=1.0">
            </head>
            <body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333; max-width: 600px; margin: 0 auto; padding: 20px;">
              <div style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); padding: 30px; text-align: center; border-radius: 10px 10px 0 0;">
                <h1 style="color: white; margin: 0; font-size: 28px;">🎉 Welcome to Kemani POS</h1>
              </div>

              <div style="background: #f9fafb; padding: 30px; border-radius: 0 0 10px 10px;">
                <h2 style="color: #1f2937; margin-top: 0;">Hello ${data.ownerName},</h2>

                <p style="font-size: 16px; color: #4b5563;">
                  Congratulations! Your business <strong>${data.businessName}</strong> has been successfully registered on Kemani POS.
                </p>

                <div style="background: white; border-left: 4px solid #667eea; padding: 20px; margin: 20px 0; border-radius: 5px;">
                  <h3 style="margin-top: 0; color: #667eea;">🚀 Next Steps:</h3>
                  <ol style="color: #4b5563; padding-left: 20px;">
                    <li>Set up your 6-digit passcode for POS security</li>
                    <li>Configure your business branding (logo, colors)</li>
                    <li>Add your first products to the inventory</li>
                    <li>Invite your staff members via email</li>
                    <li>Start processing sales!</li>
                  </ol>
                </div>

                <div style="text-align: center; margin: 30px 0;">
                  <a href="${data.dashboardUrl}" style="background: #667eea; color: white; padding: 14px 30px; text-decoration: none; border-radius: 5px; font-weight: bold; display: inline-block;">
                    Access Your Dashboard
                  </a>
                </div>

                <p style="font-size: 14px; color: #6b7280; margin-top: 30px;">
                  Need help getting started? Check out our <a href="#" style="color: #667eea;">Getting Started Guide</a> or contact our support team.
                </p>

                <hr style="border: none; border-top: 1px solid #e5e7eb; margin: 30px 0;">

                <p style="font-size: 12px; color: #9ca3af; text-align: center;">
                  This is an automated message. Please do not reply to this email.<br>
                  © ${new Date().getFullYear()} Kemani POS. All rights reserved.
                </p>
              </div>
            </body>
          </html>
        `,
      });

      if (error) {
        console.error('Failed to send registration email:', error);
        throw error;
      }

      return { success: true, messageId: result?.id };
    } catch (error) {
      console.error('Email service error:', error);
      throw new Error('Failed to send confirmation email. Please check your email configuration.');
    }
  }

  /**
   * Send staff invitation email
   */
  static async sendStaffInvitation(
    email: string,
    data: {
      businessName: string;
      staffName: string;
      role: string;
      invitationUrl: string;
      expiresAt: string;
      invitedBy: string;
    }
  ) {
    try {
      const roleDisplay = data.role
        .split('_')
        .map(word => word.charAt(0).toUpperCase() + word.slice(1))
        .join(' ');

      const expiryDate = new Date(data.expiresAt).toLocaleDateString('en-US', {
        year: 'numeric',
        month: 'long',
        day: 'numeric',
      });

      const { data: result, error } = await resend.emails.send({
        from: FROM_EMAIL,
        to: email,
        subject: `You're invited to join ${data.businessName} as ${roleDisplay}`,
        html: `
          <!DOCTYPE html>
          <html>
            <head>
              <meta charset="utf-8">
              <meta name="viewport" content="width=device-width, initial-scale=1.0">
            </head>
            <body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333; max-width: 600px; margin: 0 auto; padding: 20px;">
              <div style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); padding: 30px; text-align: center; border-radius: 10px 10px 0 0;">
                <h1 style="color: white; margin: 0; font-size: 28px;">📧 You're Invited!</h1>
              </div>

              <div style="background: #f9fafb; padding: 30px; border-radius: 0 0 10px 10px;">
                <h2 style="color: #1f2937; margin-top: 0;">Hello ${data.staffName},</h2>

                <p style="font-size: 16px; color: #4b5563;">
                  ${data.invitedBy} has invited you to join <strong>${data.businessName}</strong> on Kemani POS.
                </p>

                <div style="background: white; border-left: 4px solid #667eea; padding: 20px; margin: 20px 0; border-radius: 5px;">
                  <p style="margin: 0; color: #4b5563;">
                    <strong style="color: #667eea;">Your Role:</strong> ${roleDisplay}
                  </p>
                  <p style="margin: 10px 0 0 0; color: #4b5563;">
                    <strong style="color: #667eea;">Invitation Expires:</strong> ${expiryDate}
                  </p>
                </div>

                <p style="font-size: 16px; color: #4b5563;">
                  Click the button below to accept your invitation and set up your account:
                </p>

                <div style="text-align: center; margin: 30px 0;">
                  <a href="${data.invitationUrl}" style="background: #667eea; color: white; padding: 14px 30px; text-decoration: none; border-radius: 5px; font-weight: bold; display: inline-block;">
                    Accept Invitation
                  </a>
                </div>

                <div style="background: #fef3c7; border: 1px solid #fbbf24; padding: 15px; border-radius: 5px; margin: 20px 0;">
                  <p style="margin: 0; font-size: 14px; color: #92400e;">
                    ⚠️ <strong>Important:</strong> This invitation link will expire on ${expiryDate}. Please accept it before then.
                  </p>
                </div>

                <p style="font-size: 14px; color: #6b7280;">
                  If you didn't expect this invitation, you can safely ignore this email.
                </p>

                <hr style="border: none; border-top: 1px solid #e5e7eb; margin: 30px 0;">

                <p style="font-size: 12px; color: #9ca3af; text-align: center;">
                  This is an automated message. Please do not reply to this email.<br>
                  © ${new Date().getFullYear()} Kemani POS. All rights reserved.
                </p>
              </div>
            </body>
          </html>
        `,
      });

      if (error) {
        console.error('Failed to send invitation email:', error);
        throw error;
      }

      return { success: true, messageId: result?.id };
    } catch (error) {
      console.error('Email service error:', error);
      throw new Error('Failed to send invitation email. Please check your email configuration.');
    }
  }

  /**
   * Send password reset email (if needed)
   */
  static async sendPasswordReset(
    email: string,
    data: {
      name: string;
      resetUrl: string;
    }
  ) {
    try {
      const { data: result, error } = await resend.emails.send({
        from: FROM_EMAIL,
        to: email,
        subject: 'Reset Your Password - Kemani POS',
        html: `
          <!DOCTYPE html>
          <html>
            <head>
              <meta charset="utf-8">
              <meta name="viewport" content="width=device-width, initial-scale=1.0">
            </head>
            <body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333; max-width: 600px; margin: 0 auto; padding: 20px;">
              <div style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); padding: 30px; text-align: center; border-radius: 10px 10px 0 0;">
                <h1 style="color: white; margin: 0; font-size: 28px;">🔐 Password Reset</h1>
              </div>

              <div style="background: #f9fafb; padding: 30px; border-radius: 0 0 10px 10px;">
                <h2 style="color: #1f2937; margin-top: 0;">Hello ${data.name},</h2>

                <p style="font-size: 16px; color: #4b5563;">
                  We received a request to reset your password. Click the button below to create a new password:
                </p>

                <div style="text-align: center; margin: 30px 0;">
                  <a href="${data.resetUrl}" style="background: #667eea; color: white; padding: 14px 30px; text-decoration: none; border-radius: 5px; font-weight: bold; display: inline-block;">
                    Reset Password
                  </a>
                </div>

                <p style="font-size: 14px; color: #6b7280;">
                  If you didn't request a password reset, you can safely ignore this email.
                </p>

                <hr style="border: none; border-top: 1px solid #e5e7eb; margin: 30px 0;">

                <p style="font-size: 12px; color: #9ca3af; text-align: center;">
                  This is an automated message. Please do not reply to this email.<br>
                  © ${new Date().getFullYear()} Kemani POS. All rights reserved.
                </p>
              </div>
            </body>
          </html>
        `,
      });

      if (error) {
        console.error('Failed to send password reset email:', error);
        throw error;
      }

      return { success: true, messageId: result?.id };
    } catch (error) {
      console.error('Email service error:', error);
      throw new Error('Failed to send password reset email.');
    }
  }
}
