# Hireo App Development Plan
## PDF Generation & Template Enhancement

### Phase 1: Enhanced Application & Template Views

#### ApplicationsView Enhancements:
- Add application detail view with full application management
- Implement status tracking with timeline view
- Add document generation features (CV & Cover Letter per application)
- Include application analytics and tracking
- Add search and filter functionality

#### TemplatesView Enhancements:
- Implement template preview functionality with live preview
- Add template customization options (colors, fonts, layouts)
- Create template editor for custom templates
- Add template import/export functionality
- Implement template rating and feedback system

### Phase 2: PDF Generation with PDFKit

#### Core PDF Service:
- Create PDFGenerationService using Apple's PDFKit
- Implement CV PDF generation with dynamic layouts
- Add Cover Letter PDF generation
- Support for multiple template styles and customizations
- PDF preview and editing capabilities

#### Resume Template System:
- Create "Modern Professional" template as base template
- Implement dynamic content injection from UserProfile
- Support for multiple color schemes and fonts
- Responsive layout system for different content lengths
- Section reordering and customization

#### Data Integration:
- Map UserProfile data to template fields
- Implement custom field mapping per application
- Add template variable system for dynamic content
- Support for conditional sections based on user data

### Phase 3: Advanced Features

#### Template Features:
- Multi-language template support
- Template versioning system
- Custom section builder
- Advanced layout customization
- Template marketplace (future)

#### PDF Features:
- Batch PDF generation
- PDF digital signatures
- PDF optimization for different use cases
- Export to multiple formats (PDF, Word, etc.)
- Print optimization

### Implementation Priority:
1. PDF Generation Service foundation
2. Basic Modern Professional template
3. Data mapping and injection logic
4. Enhanced ApplicationsView with PDF generation
5. Template customization interface
6. Advanced PDF features

## PDF Generation Implementation Plan for Classic Template

### Current Issue Analysis:
- The current PDFGenerationService creates blank PDFs because it's not properly rendering content to PDF pages
- The renderPage() method creates UIViews but doesn't convert them to PDF content
- Missing proper PDF graphics context for drawing content

### Solution Architecture:

#### 1. Fix Core PDF Generation Issue
**Problem**: The current implementation creates UIViews but doesn't render them to PDF graphics context
**Solution**: Replace UIView-based rendering with direct PDF graphics drawing using PDFKit and Core Graphics

#### 2. Classic Template Design Specifications
**Layout**: Professional single-column layout with clear sections
**Typography**: 
- Header: 24pt Bold for name, 14pt for title
- Section headers: 16pt Bold with accent color
- Content: 11pt regular, 10pt for dates/details
**Colors**: 
- Primary: #2C3E50 (Dark Blue-Gray) for headers and accents
- Text: #2C3E50 for main content, #7F8C8D for secondary content
**Sections Order**:
1. Header (Name, Title, Contact Info)
2. Professional Summary (if available)
3. Work Experience
4. Education
5. Skills
6. Projects (if any)
7. Certifications (if any)
8. Languages (if any)

#### 3. Implementation Steps

**Step 1: Create ClassicTemplatePDFRenderer**
- Dedicated renderer class for classic template styling
- Direct PDF graphics context drawing
- Professional typography and spacing

**Step 2: Implement Graphics Drawing Methods**
- Text drawing with proper fonts and colors
- Line drawing for separators and accents
- Layout calculations for dynamic content

**Step 3: Content Sectioning System**
- Header rendering with contact information layout
- Dynamic section rendering based on user data
- Proper spacing and page break handling

**Step 4: Typography and Styling**
- Font selection and sizing system
- Color scheme application
- Professional spacing and margins (40pt margins)

#### 4. Technical Implementation Details

**PDF Page Setup**:
- A4 size (595 x 842 points)
- 40pt margins on all sides
- Content area: 515 x 762 points

**Drawing Context Methods**:
```swift
- drawText(text: String, at: CGPoint, font: UIFont, color: UIColor, maxWidth: CGFloat)
- drawHeader(userProfile: UserProfile, in: CGRect)
- drawSection(title: String, content: [Any], at: CGPoint) -> CGFloat
- drawWorkExperience(experience: WorkExperienceEntry, at: CGPoint) -> CGFloat
- drawEducation(education: EducationEntry, at: CGPoint) -> CGFloat
```

**Layout System**:
- Dynamic height calculations for content
- Automatic page breaks when content exceeds page height
- Section-aware page breaking (don't break in middle of entries)

#### 5. Classic Template Visual Design

**Header Layout**:
```
[Name - 24pt Bold, Primary Color]
[Professional Title - 14pt Regular, Secondary Color]

[Email] • [Phone] • [Address]
[LinkedIn] • [Website] (if available)
```

**Section Layout**:
```
SECTION TITLE (16pt Bold, Primary Color, ALL CAPS)
────────────────────────────────────────

Content entries with consistent spacing
- Bold titles for positions/degrees
- Company/institution names in regular font
- Dates right-aligned in gray
- Descriptions with proper line spacing
```

#### 6. Error Handling and Edge Cases
- Handle missing or empty profile data gracefully
- Manage long content with proper text wrapping
- Ensure readable layout with varying content lengths
- Fallback fonts if system fonts unavailable

#### 7. Testing Checklist
- [ ] Generate PDF with minimal profile data
- [ ] Generate PDF with complete profile data
- [ ] Test with long descriptions and multiple entries
- [ ] Verify typography and spacing consistency
- [ ] Check page breaks and multi-page handling
- [ ] Validate color accuracy and professional appearance

