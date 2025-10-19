#!/bin/bash

# FietsRouteMee Version Management Script
# Usage: ./scripts/version.sh [major|minor|patch|show|set <version>]

set -e

VERSION_FILE="VERSION"
CHANGELOG_FILE="CHANGELOG.md"
INFO_PLIST="FietsRouteMee/Info.plist"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to get current version
get_current_version() {
    if [ -f "$VERSION_FILE" ]; then
        cat "$VERSION_FILE"
    else
        echo "0.0.0"
    fi
}

# Function to increment version
increment_version() {
    local version=$1
    local type=$2
    
    IFS='.' read -ra VERSION_PARTS <<< "$version"
    local major=${VERSION_PARTS[0]}
    local minor=${VERSION_PARTS[1]}
    local patch=${VERSION_PARTS[2]}
    
    case $type in
        major)
            major=$((major + 1))
            minor=0
            patch=0
            ;;
        minor)
            minor=$((minor + 1))
            patch=0
            ;;
        patch)
            patch=$((patch + 1))
            ;;
        *)
            echo -e "${RED}Error: Invalid version type. Use major, minor, or patch${NC}"
            exit 1
            ;;
    esac
    
    echo "$major.$minor.$patch"
}

# Function to update Info.plist
update_info_plist() {
    local version=$1
    local build_number=$(date +%Y%m%d%H%M)
    
    echo -e "${BLUE}Updating Info.plist...${NC}"
    
    # Update CFBundleShortVersionString
    /usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $version" "$INFO_PLIST" 2>/dev/null || \
    /usr/libexec/PlistBuddy -c "Add :CFBundleShortVersionString string $version" "$INFO_PLIST"
    
    # Update CFBundleVersion
    /usr/libexec/PlistBuddy -c "Set :CFBundleVersion $build_number" "$INFO_PLIST" 2>/dev/null || \
    /usr/libexec/PlistBuddy -c "Add :CFBundleVersion string $build_number" "$INFO_PLIST"
    
    echo -e "${GREEN}✅ Info.plist updated with version $version (build $build_number)${NC}"
}

# Function to update VERSION file
update_version_file() {
    local version=$1
    echo "$version" > "$VERSION_FILE"
    echo -e "${GREEN}✅ VERSION file updated to $version${NC}"
}

# Function to create git tag
create_git_tag() {
    local version=$1
    local tag="v$version"
    
    echo -e "${BLUE}Creating git tag: $tag${NC}"
    git add .
    git commit -m "🚀 Release version $version" || true
    git tag -a "$tag" -m "Release version $version"
    
    echo -e "${GREEN}✅ Git tag $tag created${NC}"
}

# Function to show current version
show_version() {
    local version=$(get_current_version)
    echo -e "${BLUE}Current version: ${GREEN}$version${NC}"
    
    # Show Info.plist version if it exists
    if [ -f "$INFO_PLIST" ]; then
        local plist_version=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$INFO_PLIST" 2>/dev/null || echo "Not set")
        local build_number=$(/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" "$INFO_PLIST" 2>/dev/null || echo "Not set")
        echo -e "${BLUE}Info.plist version: ${GREEN}$plist_version${NC}"
        echo -e "${BLUE}Build number: ${GREEN}$build_number${NC}"
    fi
}

# Main script logic
case "$1" in
    major|minor|patch)
        current_version=$(get_current_version)
        new_version=$(increment_version "$current_version" "$1")
        
        echo -e "${YELLOW}Current version: $current_version${NC}"
        echo -e "${YELLOW}New version: $new_version${NC}"
        
        read -p "Continue with version bump? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            update_version_file "$new_version"
            update_info_plist "$new_version"
            create_git_tag "$new_version"
            
            echo -e "${GREEN}🎉 Version bumped to $new_version!${NC}"
            echo -e "${BLUE}Don't forget to:${NC}"
            echo -e "  • Update CHANGELOG.md"
            echo -e "  • Push changes: git push origin main --tags"
            echo -e "  • Create GitHub release"
        else
            echo -e "${YELLOW}Version bump cancelled${NC}"
        fi
        ;;
    set)
        if [ -z "$2" ]; then
            echo -e "${RED}Error: Please provide a version number${NC}"
            echo "Usage: $0 set 1.2.3"
            exit 1
        fi
        
        new_version="$2"
        echo -e "${YELLOW}Setting version to: $new_version${NC}"
        
        update_version_file "$new_version"
        update_info_plist "$new_version"
        create_git_tag "$new_version"
        
        echo -e "${GREEN}🎉 Version set to $new_version!${NC}"
        ;;
    show)
        show_version
        ;;
    *)
        echo -e "${BLUE}FietsRouteMee Version Management${NC}"
        echo ""
        echo "Usage: $0 [command]"
        echo ""
        echo "Commands:"
        echo "  major     Bump major version (1.0.0 -> 2.0.0)"
        echo "  minor     Bump minor version (1.0.0 -> 1.1.0)"
        echo "  patch     Bump patch version (1.0.0 -> 1.0.1)"
        echo "  set <v>   Set specific version (e.g., 1.2.3)"
        echo "  show      Show current version"
        echo ""
        echo "Examples:"
        echo "  $0 patch          # 1.0.0 -> 1.0.1"
        echo "  $0 minor          # 1.0.1 -> 1.1.0"
        echo "  $0 set 2.0.0      # Set to 2.0.0"
        echo "  $0 show           # Show current version"
        ;;
esac
