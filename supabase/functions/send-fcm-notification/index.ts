import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

interface NotificationPayload {
  user_id: string
  title: string
  body: string
  data?: Record<string, any>
}

Deno.serve(async (req) => {
  try {
    // Get request body
    const payload: NotificationPayload = await req.json()
    const { user_id, title, body, data } = payload

    if (!user_id || !title || !body) {
      return new Response(
        JSON.stringify({ error: 'Missing required fields: user_id, title, body' }),
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      )
    }

    // Create Supabase client with service role key
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    const supabase = createClient(supabaseUrl, supabaseServiceKey)

    // Get user's FCM token
    const { data: profile, error: profileError } = await supabase
      .from('user_profiles')
      .select('fcm_token')
      .eq('id', user_id)
      .single()

    if (profileError || !profile?.fcm_token) {
      console.log(`No FCM token found for user ${user_id}`)
      return new Response(
        JSON.stringify({ 
          success: false, 
          message: 'No FCM token found for user',
          notification_inserted: true 
        }),
        { status: 200, headers: { 'Content-Type': 'application/json' } }
      )
    }

    // Send FCM notification via Firebase API
    const firebaseServerKey = Deno.env.get('FIREBASE_SERVER_KEY')
    
    if (!firebaseServerKey) {
      console.log('FIREBASE_SERVER_KEY not configured')
      return new Response(
        JSON.stringify({ 
          success: false, 
          message: 'Firebase not configured',
          notification_inserted: true 
        }),
        { status: 200, headers: { 'Content-Type': 'application/json' } }
      )
    }

    const fcmResponse = await fetch('https://fcm.googleapis.com/fcm/send', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `key=${firebaseServerKey}`,
      },
      body: JSON.stringify({
        to: profile.fcm_token,
        notification: {
          title,
          body,
        },
        data: data || {},
        priority: 'high',
      }),
    })

    if (!fcmResponse.ok) {
      const errorText = await fcmResponse.text()
      console.error('FCM send failed:', errorText)
      return new Response(
        JSON.stringify({ 
          success: false, 
          message: 'FCM send failed',
          error: errorText,
          notification_inserted: true 
        }),
        { status: 200, headers: { 'Content-Type': 'application/json' } }
      )
    }

    const fcmResult = await fcmResponse.json()
    console.log('FCM sent successfully:', fcmResult)

    return new Response(
      JSON.stringify({ 
        success: true, 
        message: 'Notification sent successfully',
        fcm_result: fcmResult 
      }),
      { status: 200, headers: { 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    console.error('Error in send-fcm-notification:', error)
    return new Response(
      JSON.stringify({ 
        success: false, 
        error: error.message 
      }),
      { status: 500, headers: { 'Content-Type': 'application/json' } }
    )
  }
})
