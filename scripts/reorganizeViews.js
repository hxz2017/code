fs = require('fs')
_ = require('lodash')
_.string = require('underscore.string')

var directories = ['./app/views', './app/templates', './app/styles', './test/app/views']
var groupings = {};

while(directories.length) {
  directory = directories.pop()

  fs.readdirSync(directory).forEach((fileOrDir) => {
    absPath = directory + '/' + fileOrDir
    stat = fs.statSync(absPath)
  
    // .coffee => .js
    if(stat.isFile()) {
      var group = _.string.underscored(fileOrDir.split('.')[0])
      if(_.string.endsWith(group, '_view') || _.string.endsWith(group, '_modal')) {
        if(!groupings[group]) groupings[group] = []
        groupings[group].push(absPath)
      }
    }
  
    // Add to list of directories to walk
    if(stat.isDirectory()) {
      directories.push(absPath);
    }
  })
}
console.log('groupings', JSON.stringify(groupings, null, '\t'))

_.forEach(groupings, function(files) {
  var viewAbsPath = _.remove(files, (file) => _.string.startsWith(file, './app/views/'))[0]
  if(!viewAbsPath || _.size(files) === 0) return;
  var viewFolder = viewAbsPath.slice(0, _.lastIndexOf(viewAbsPath, '/') + 1)

  console.log('Migrating view:', viewAbsPath)
  console.log('\tfiles:', JSON.stringify(files, null, '\t'))
  if (!_.find(fs.readdirSync(viewFolder), (file) => _.string.startsWith(file, 'index.'))) {
    // Deduce data
    viewFileName = viewAbsPath.slice(_.lastIndexOf(viewAbsPath, '/')+1)
    viewFileNameWithoutExt = viewFileName.replace('.coffee', '')
    newViewFolder = viewFolder + viewFileNameWithoutExt + '/'
    newViewAbsPath = newViewFolder + viewFileName
    indexFilePath = newViewFolder + 'index.coffee'
    indexFileData = `module.exports = require './${viewFileNameWithoutExt}'`

    // Move view file into folder
    console.log('\tMove view into dedicated folder, add index file')
    try { fs.mkdirSync(newViewFolder) } catch (e) { ; }
    fs.renameSync(viewAbsPath, newViewAbsPath)
    fs.writeFileSync(indexFilePath, indexFileData, {encoding: 'utf8'})
    
    // Update variables
    viewFolder = newViewFolder
    viewAbsPath = newViewAbsPath
    
    // Update requires from within the view
    viewFileData = fs.readFileSync(viewAbsPath, {encoding: 'utf8'})
    viewFileData = viewFileData
      .replace(new RegExp("(require[ (]['\"])\..\/", 'gm'), '$1../../') // require("../FileName") -> require("../../FileName")
      .replace(new RegExp("(require[ (]['\"])\.\/", 'gm'), '$1../') // require("../FileName") -> require("../../FileName")
    fs.writeFileSync(viewAbsPath, viewFileData, {encoding: 'utf8'})
  }

  var templateAbsPath = _.remove(files, (file) => _.string.startsWith(file, './app/templates/'))[0]
  if(templateAbsPath) {
    // Deduce data
    viewFileData = fs.readFileSync(viewAbsPath, {encoding: 'utf8'})
    templateFileName = templateAbsPath.slice(_.lastIndexOf(templateAbsPath, '/'))
    newTemplateAbsPath = viewFolder + templateFileName
    templateFileNameWithoutExt = templateFileName.replace('.jade', '').slice(1)
    oldTemplatePathRegExp = new RegExp('templates/(\\S+\\/)?'+templateFileNameWithoutExt, 'gm')
    newViewFileData = viewFileData.replace(oldTemplatePathRegExp, './'+templateFileNameWithoutExt)
  
    // Move the template into the view folder, edit view require to point to new template location
    fs.writeFileSync(viewAbsPath, newViewFileData, {encoding: 'utf8'})
    fs.renameSync(templateAbsPath, newTemplateAbsPath)
    
    // Update variables
    templateAbsPath = newTemplateAbsPath

    // Update relative include paths
    templateFileData = fs.readFileSync(templateAbsPath, {encoding: 'utf8'})
    templateFileData = templateFileData
      .replace("include ./teacher-dashboard-nav.jade", "include /templates/courses/teacher-dashboard-nav.jade")
      .replace("include ../courses/teacher-dashboard-nav.jade", "include /templates/courses/teacher-dashboard-nav.jade")
      .replace("extends /templates/editor/modal/save-version-modal", "extends /views/editor/modal/SaveVersionModal/save-version-modal")
      .replace("extends /templates/editor/modal/new-model-modal", "extends /views/editor/modal/NewModelModal/new-model-modal")
    fs.writeFileSync(templateAbsPath, templateFileData, { encoding: 'utf8' })
  }
  
  var testAbsPath = _.remove(files, (file) => _.string.startsWith(file, './test/app'))[0]
  if(testAbsPath) {
    // Deduce data
    testFileName = testAbsPath.slice(_.lastIndexOf(testAbsPath, '/'))
    newTestAbsPath = viewFolder + testFileName
  
    // Move test file into view folder
    fs.renameSync(testAbsPath, newTestAbsPath)
  }

  var styleAbsPath = _.remove(files, (file) => _.string.startsWith(file, './app/styles'))[0]
  if(styleAbsPath) {
    // Deduce data
    styleFileName = styleAbsPath.slice(_.lastIndexOf(styleAbsPath, '/'))
    newStyleAbsPath = viewFolder + styleFileName

    // Move style file into view folder
    fs.renameSync(styleAbsPath, newStyleAbsPath)
  }
});
