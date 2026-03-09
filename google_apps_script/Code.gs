// ============================================================================
// WIFAQ ASSOCIATION - GOOGLE APPS SCRIPT BACKEND
// ============================================================================
// Ce script gère toutes les opérations CRUD pour l'application Flutter
// ============================================================================

// CONFIGURATION
const API_KEY = 'wifaq_mo94so99ro04ma10'; // Clé API pour sécuriser les requêtes
const SPREADSHEET_ID = '1NBUJGU4C52bcXk4dbbBiClel9qmPobTdmkHCXSpsqTo'; // À remplacer par votre ID de Google Sheets
const DRIVE_FOLDER_ID = '1k9zUA6csZiy3sza5Pwi0DxH6ZgiNIHPa'; // Dossier Drive pour les photos

// Noms des feuilles (correspondant à votre structure existante)
const SHEETS = {
  SETTINGS: 'settings',
  REGISTRATIONS: 'registrations',
  EXECUTIVE_MEMBERS: 'executive_members',
  ACHIEVEMENTS: 'achievements',
  ACHIEVEMENT_PHOTOS: 'achievement_photos',
  OBJECTIVES: 'objectives',
  MANIFESTATIONS: 'manifestations',
  SYNC_LOG: 'sync_log'
};

// ============================================================================
// POINT D'ENTRÉE PRINCIPAL - OPTIONS (pour CORS preflight)
// ============================================================================
function doOptions(e) {
  return jsonResponse({ ok: true });
}

// ============================================================================
// POINT D'ENTRÉE PRINCIPAL - GET
// ============================================================================
function doGet(e) {
  try {
    const action = e.parameter.action;
    const entity = e.parameter.entity;
    
    if (!action || !entity) {
      return jsonResponse({ ok: false, error: 'Missing action or entity parameter' });
    }
    
    if (action === 'list') {
      const data = listEntity(entity);
      return jsonResponse({ ok: true, data: data });
    }
    
    return jsonResponse({ ok: false, error: 'Unknown action: ' + action });
  } catch (error) {
    Logger.log('doGet Error: ' + error.toString());
    return jsonResponse({ ok: false, error: error.toString() });
  }
}

// ============================================================================
// POINT D'ENTRÉE PRINCIPAL - POST
// ============================================================================
function doPost(e) {
  try {
    // Parser le payload JSON
    const payload = JSON.parse(e.postData.contents);
    
    // Vérifier la clé API
    if (payload.apiKey !== API_KEY) {
      return jsonResponse({ ok: false, error: 'Invalid API key' });
    }
    
    const action = payload.action;
    
    Logger.log('POST Action: ' + action);
    Logger.log('Payload: ' + JSON.stringify(payload));
    
    // Router vers la bonne action
    switch (action) {
      case 'upsert':
        return handleUpsert(payload);
      case 'batchUpsert':
        return handleBatchUpsert(payload);
      case 'delete':
        return handleDelete(payload);
      case 'batchDelete':
        return handleBatchDelete(payload);
      case 'uploadImage':
        return handleUploadImage(payload);
      default:
        return jsonResponse({ ok: false, error: 'Unknown action: ' + action });
    }
  } catch (error) {
    Logger.log('doPost Error: ' + error.toString());
    return jsonResponse({ ok: false, error: error.toString() });
  }
}

// ============================================================================
// GESTION DES OPÉRATIONS UPSERT
// ============================================================================
function handleUpsert(payload) {
  const entity = payload.entity;
  const data = payload.data;
  
  if (!entity || !data) {
    return jsonResponse({ ok: false, error: 'Missing entity or data' });
  }
  
  const sheetName = getSheetName(entity);
  const sheet = getOrCreateSheet(sheetName);
  
  upsertRow(sheet, entity, data);
  
  return jsonResponse({ ok: true, message: 'Data saved successfully' });
}

function handleBatchUpsert(payload) {
  const entity = payload.entity;
  const dataArray = payload.data;
  
  if (!entity || !Array.isArray(dataArray)) {
    return jsonResponse({ ok: false, error: 'Missing entity or data array' });
  }
  
  const sheetName = getSheetName(entity);
  const sheet = getOrCreateSheet(sheetName);
  
  dataArray.forEach(data => {
    upsertRow(sheet, entity, data);
  });
  
  return jsonResponse({ ok: true, message: 'Batch data saved successfully' });
}

// ============================================================================
// GESTION DES OPÉRATIONS DELETE
// ============================================================================
function handleDelete(payload) {
  const entity = payload.entity;
  const id = payload.id;
  
  if (!entity || !id) {
    return jsonResponse({ ok: false, error: 'Missing entity or id' });
  }
  
  const sheetName = getSheetName(entity);
  const sheet = getOrCreateSheet(sheetName);
  
  deleteRow(sheet, id, entity);
  
  return jsonResponse({ ok: true, message: 'Data deleted successfully' });
}

function handleBatchDelete(payload) {
  const entity = payload.entity;
  const ids = payload.ids;
  
  if (!entity || !Array.isArray(ids)) {
    return jsonResponse({ ok: false, error: 'Missing entity or ids array' });
  }
  
  const sheetName = getSheetName(entity);
  const sheet = getOrCreateSheet(sheetName);
  
  ids.forEach(id => {
    deleteRow(sheet, id, entity);
  });
  
  return jsonResponse({ ok: true, message: 'Batch data deleted successfully' });
}

// ============================================================================
// GESTION DES UPLOADS D'IMAGES
// ============================================================================
function handleUploadImage(payload) {
  try {
    const base64Data = payload.base64;
    const fileName = payload.fileName || 'image.jpg';
    const mimeType = payload.mimeType || 'image/jpeg';
    
    if (!base64Data) {
      return jsonResponse({ ok: false, error: 'Missing image data' });
    }
    
    // Décoder base64
    const blob = Utilities.newBlob(Utilities.base64Decode(base64Data), mimeType, fileName);
    
    // Récupérer le dossier Drive par son ID
    const folder = DriveApp.getFolderById(DRIVE_FOLDER_ID);
    
    // Uploader le fichier
    const file = folder.createFile(blob);
    file.setSharing(DriveApp.Access.ANYONE_WITH_LINK, DriveApp.Permission.VIEW);
    
    const fileId = file.getId();
    // Utiliser l'URL thumbnail pour éviter les problèmes CORS dans les navigateurs web
    const url = 'https://drive.google.com/thumbnail?id=' + fileId + '&sz=w1000';
    
    return jsonResponse({ 
      ok: true, 
      data: { 
        file_id: fileId, 
        url: url 
      } 
    });
  } catch (error) {
    Logger.log('Upload Error: ' + error.toString());
    return jsonResponse({ ok: false, error: error.toString() });
  }
}

// ============================================================================
// FONCTIONS UTILITAIRES - SHEETS
// ============================================================================
function getSheetName(entity) {
  const mapping = {
    'registrations': SHEETS.REGISTRATIONS,
    'executive_members': SHEETS.EXECUTIVE_MEMBERS,
    'achievements': SHEETS.ACHIEVEMENTS,
    'achievement_photos': SHEETS.ACHIEVEMENT_PHOTOS,
    'objectives': SHEETS.OBJECTIVES,
    'manifestations': SHEETS.MANIFESTATIONS
  };
  return mapping[entity] || entity;
}

function getOrCreateSheet(sheetName) {
  const ss = SpreadsheetApp.openById(SPREADSHEET_ID);
  let sheet = ss.getSheetByName(sheetName);
  
  if (!sheet) {
    sheet = ss.insertSheet(sheetName);
    initializeSheet(sheet, sheetName);
  }
  
  return sheet;
}

function initializeSheet(sheet, sheetName) {
  // Initialiser les en-têtes selon le type de feuille (structure existante de l'utilisateur)
  let headers = [];
  
  switch (sheetName) {
    case SHEETS.SETTINGS:
      headers = ['key', 'value', 'updated_at'];
      break;
    case SHEETS.REGISTRATIONS:
      headers = ['id', 'full_name', 'phone', 'email', 'city', 'notes', 
                 'wants_membership_card', 'photo_drive_file_id', 'photo_url', 
                 'created_at', 'updated_at', 'is_deleted'];
      break;
    case SHEETS.EXECUTIVE_MEMBERS:
      headers = ['id', 'name', 'role', 'order_index',
                 'photo_drive_file_id', 'photo_url',
                 'created_at', 'updated_at', 'is_deleted'];
      break;
    case SHEETS.OBJECTIVES:
      headers = ['id', 'text', 'order_index',
                 'created_at', 'updated_at', 'is_deleted'];
      break;
    case SHEETS.ACHIEVEMENTS:
      headers = ['id', 'year', 'description', 'status', 'order_index',
                 'created_at', 'updated_at', 'is_deleted'];
      break;
    case SHEETS.ACHIEVEMENT_PHOTOS:
      headers = ['id', 'achievement_id', 'photo_drive_file_id', 'photo_url', 'order_index',
                 'created_at', 'updated_at', 'is_deleted'];
      break;
    case SHEETS.MANIFESTATIONS:
      headers = ['id', 'title', 'details', 'date',
                 'photo_drive_file_id', 'photo_url',
                 'created_at', 'updated_at', 'is_deleted'];
      break;
    case SHEETS.SYNC_LOG:
      headers = ['id', 'entity', 'entity_id', 'action', 'actor', 'created_at'];
      break;
    default:
      headers = ['id', 'data', 'created_at', 'updated_at', 'is_deleted'];
  }
  
  if (headers.length > 0) {
    sheet.getRange(1, 1, 1, headers.length).setValues([headers]);
    sheet.getRange(1, 1, 1, headers.length).setFontWeight('bold');
  }
}

function listEntity(entity) {
  const sheetName = getSheetName(entity);
  const sheet = getOrCreateSheet(sheetName);
  
  const lastRow = sheet.getLastRow();
  if (lastRow <= 1) {
    return [];
  }
  
  const headers = sheet.getRange(1, 1, 1, sheet.getLastColumn()).getValues()[0];
  const data = sheet.getRange(2, 1, lastRow - 1, headers.length).getValues();
  
  return data.map(row => {
    const obj = {};
    headers.forEach((header, index) => {
      obj[header] = row[index];
    });
    return obj;
  });
}

function upsertRow(sheet, entity, data) {
  const headers = sheet.getRange(1, 1, 1, sheet.getLastColumn()).getValues()[0];
  const id = data.id ? data.id.toString() : '';
  
  if (!id) {
    Logger.log('Warning: No ID provided for upsert');
    return;
  }
  
  Logger.log('Upsert data for ' + entity + ': ' + JSON.stringify(data));
  
  // Chercher si la ligne existe déjà
  const lastRow = sheet.getLastRow();
  let rowIndex = -1;
  
  if (lastRow > 1) {
    const idColumn = headers.indexOf('id') + 1;
    const ids = sheet.getRange(2, idColumn, lastRow - 1, 1).getValues();
    
    for (let i = 0; i < ids.length; i++) {
      if (ids[i][0].toString() === id) {
        rowIndex = i + 2; // +2 car on commence à la ligne 2 et i est 0-indexed
        break;
      }
    }
  }
  
  // Ajouter updated_at timestamp
  const now = new Date().toISOString();
  if (headers.indexOf('updated_at') !== -1) {
    data.updated_at = now;
  }
  
  // Si c'est une nouvelle ligne et qu'il y a created_at, l'ajouter
  if (rowIndex === -1 && headers.indexOf('created_at') !== -1 && !data.created_at) {
    data.created_at = now;
  }
  
  // Préparer les valeurs
  const values = headers.map(header => {
    if (data.hasOwnProperty(header)) {
      const value = data[header];
      return value !== null && value !== undefined ? value : '';
    }
    return '';
  });
  
  Logger.log('Headers: ' + JSON.stringify(headers));
  Logger.log('Values: ' + JSON.stringify(values));
  
  // Insérer ou mettre à jour
  if (rowIndex === -1) {
    // Nouvelle ligne
    sheet.appendRow(values);
    Logger.log('Inserted new row with ID: ' + id);
    
    // Log dans sync_log si disponible
    logSync(entity, id, 'insert', 'app');
  } else {
    // Mise à jour
    sheet.getRange(rowIndex, 1, 1, values.length).setValues([values]);
    Logger.log('Updated row with ID: ' + id);
    
    // Log dans sync_log si disponible
    logSync(entity, id, 'update', 'app');
  }
}

function deleteRow(sheet, id, entity) {
  const headers = sheet.getRange(1, 1, 1, sheet.getLastColumn()).getValues()[0];
  const lastRow = sheet.getLastRow();
  
  if (lastRow <= 1) return;
  
  const idColumn = headers.indexOf('id') + 1;
  const isDeletedColumn = headers.indexOf('is_deleted') + 1;
  const updatedAtColumn = headers.indexOf('updated_at') + 1;
  
  if (isDeletedColumn === 0) {
    Logger.log('Warning: No is_deleted column found');
    return;
  }
  
  const ids = sheet.getRange(2, idColumn, lastRow - 1, 1).getValues();
  
  for (let i = 0; i < ids.length; i++) {
    if (ids[i][0].toString() === id.toString()) {
      const rowIndex = i + 2;
      sheet.getRange(rowIndex, isDeletedColumn).setValue(true);
      
      // Mettre à jour updated_at si la colonne existe
      if (updatedAtColumn > 0) {
        sheet.getRange(rowIndex, updatedAtColumn).setValue(new Date().toISOString());
      }
      
      Logger.log('Marked row as deleted with ID: ' + id);
      
      // Log dans sync_log si disponible
      logSync(entity, id, 'delete', 'app');
      break;
    }
  }
}

// ============================================================================
// FONCTION DE LOGGING SYNC
// ============================================================================
function logSync(entity, entityId, action, actor) {
  try {
    const ss = SpreadsheetApp.openById(SPREADSHEET_ID);
    const syncSheet = ss.getSheetByName(SHEETS.SYNC_LOG);
    
    if (!syncSheet) {
      // Si la feuille sync_log n'existe pas, on ne fait rien
      return;
    }
    
    const logId = new Date().getTime().toString();
    const createdAt = new Date().toISOString();
    
    syncSheet.appendRow([logId, entity, entityId, action, actor, createdAt]);
  } catch (error) {
    // Ne pas bloquer l'opération principale si le log échoue
    Logger.log('Sync log error: ' + error.toString());
  }
}

// ============================================================================
// FONCTIONS UTILITAIRES - DRIVE
// ============================================================================
function getOrCreateFolder(folderName) {
  const folders = DriveApp.getFoldersByName(folderName);
  
  if (folders.hasNext()) {
    return folders.next();
  }
  
  return DriveApp.createFolder(folderName);
}

// ============================================================================
// FONCTIONS UTILITAIRES - RÉPONSES
// ============================================================================
function jsonResponse(obj) {
  return ContentService
    .createTextOutput(JSON.stringify(obj))
    .setMimeType(ContentService.MimeType.JSON);
}
