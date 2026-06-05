/// <reference types="vite/client" />

import {
  Configuration,
  PublicClientApplication,
  AccountInfo,
  InteractionRequiredAuthError,
} from '@azure/msal-browser'

// MSAL configuration
const msalConfig: Configuration = {
  auth: {
    clientId: import.meta.env.VITE_ENTRA_CLIENT_ID || '',
    authority: `https://login.microsoftonline.com/${import.meta.env.VITE_ENTRA_TENANT_ID || 'common'}`,
    redirectUri: window.location.origin,
  },
  cache: {
    cacheLocation: 'localStorage',
    storeAuthStateInCookie: false,
  },
}

// Create the MSAL instance
export const msalInstance = new PublicClientApplication(msalConfig)

// API scope - uses Agent Blueprint ID for Agent ID flow
// Format: api://{agent-blueprint-id}/access_as_user
export const apiRequest = {
  scopes: [import.meta.env.VITE_ENTRA_API_SCOPE || 'api://agent0-api/.default'],
}

// Scopes for login and API access. Include the Agent API scope at sign-in so
// the later chat request can usually acquire an API token silently.
export const loginRequest = {
  scopes: ['openid', 'profile', 'email', 'User.Read', ...apiRequest.scopes],
}

// Graph API scope for getting user photo
export const graphRequest = {
  scopes: ['User.Read'],
}

function logTokenSummary(accessToken: string, label: string) {
  try {
    const [, payload] = accessToken.split('.')
    const decoded = JSON.parse(atob(payload))
    console.info(`${label} token summary`, {
      aud: decoded.aud,
      scp: decoded.scp,
      iss: decoded.iss,
      exp: decoded.exp,
    })
  } catch (error) {
    console.warn(`Could not decode ${label} token payload`, error)
  }
}

// Helper to get access token for the Agent API.
export async function getAccessToken(
  account: AccountInfo | null
): Promise<string | null> {
  if (!account) {
    console.error('Cannot acquire API token: no MSAL account is active')
    return null
  }

  console.info('Acquiring Agent API token silently', {
    account: account.username,
    scopes: apiRequest.scopes,
  })

  try {
    const response = await msalInstance.acquireTokenSilent({
      ...apiRequest,
      account,
    })
    logTokenSummary(response.accessToken, 'Agent API')
    return response.accessToken
  } catch (error) {
    console.error('Failed to acquire Agent API token silently:', error)

    if (error instanceof InteractionRequiredAuthError) {
      // A custom API scope often needs interactive consent the first time.
      // Use popup because the rest of this app already signs in with popup.
      try {
        console.info('Trying interactive popup for Agent API token', apiRequest.scopes)
        const response = await msalInstance.acquireTokenPopup(apiRequest)
        logTokenSummary(response.accessToken, 'Agent API')
        return response.accessToken
      } catch (popupError) {
        console.error('Failed to acquire Agent API token via popup:', popupError)
        return null
      }
    }

    return null
  }
}

// Helper to get Graph access token for user photo
export async function getGraphToken(
  account: AccountInfo | null
): Promise<string | null> {
  if (!account) {
    return null
  }

  try {
    const response = await msalInstance.acquireTokenSilent({
      ...graphRequest,
      account,
    })
    return response.accessToken
  } catch (error) {
    console.error('Failed to acquire Graph token:', error)
    return null
  }
}

// Fetch user photo from Microsoft Graph
export async function fetchUserPhoto(account: AccountInfo | null): Promise<string | null> {
  const token = await getGraphToken(account)
  if (!token) {
    return null
  }

  try {
    const response = await fetch('https://graph.microsoft.com/v1.0/me/photo/$value', {
      headers: {
        Authorization: `Bearer ${token}`,
      },
    })

    if (!response.ok) {
      // User may not have a photo set
      if (response.status === 404) {
        return null
      }
      throw new Error(`Failed to fetch photo: ${response.status}`)
    }

    const blob = await response.blob()
    return URL.createObjectURL(blob)
  } catch (error) {
    console.error('Error fetching user photo:', error)
    return null
  }
}

// User type for compatibility with existing components
export interface EntraUser {
  sub?: string
  name?: string
  email?: string
  picture?: string
}

// Convert MSAL AccountInfo to EntraUser
export function accountToUser(account: AccountInfo | null, picture?: string): EntraUser | undefined {
  if (!account) return undefined

  return {
    sub: account.localAccountId,
    name: account.name || account.username,
    email: account.username,
    picture: picture,
  }
}
